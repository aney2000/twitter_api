# Prompt History — Week 8, Tweet Comments

Chronological log of every prompt used to build the comments feature, what came back, and the
verdict. Drafted from the session transcript.

---

## 1. Install the plugins

```
/plugin marketplace add agilefreaks/claude-skills
/plugin install feature-development@agilefreaks-skills
/plugin install code-review@agilefreaks-skills
```

**What came back:** Marketplace added, both plugins installed and active. No model output —
these are harness commands, not prompts.

**Verdict:** accepted.

---

## 2. Set up the feature-development skill

> set up feature-development

**What came back:** Claude scanned the project first — found no `CLAUDE.md` and no
`.claude/rules/`, identified RSpec as the suite with specs split into `models/`, `services/`
and `requests/graphql/`, read `.github/workflows/ci.yml` for the real commands, and noticed the
de-facto `work/weekN` branch pattern without a document backing it. It then asked four
questions: branching, spec capture, test-collaboration mode, and commit granularity.

Answers given: **stay on the current branch**, inline spec note, **Solo AI**, checkpoint + curate.

It wrote `.claude/rules/feature-development.md` containing only the one non-default choice
(branching), and flagged a consequence I hadn't considered: staying on a shared branch means
commit curation would rewrite history that might already be pushed.

**Verdict:** accepted. Solo AI was the required choice per the exercise brief — the other modes
have the human writing assertions, which this exercise doesn't allow.

---

## 3. Set up the code-review skill

> set up code-review

**What came back:** Detected that `gh` is not installed on this machine, which constrains
everything — no PR reading, no PR posting, no CI status checks. Asked four questions: how to
deliver reviews, how to verify the build, which project-specific conventions to enforce, and
whether to generate a CI workflow.

Answers given: **post to PR (install `gh`)**, **run checks locally**, *(conventions question left
unanswered)*, **skip the CI workflow**.

Claude wrote `.claude/rules/code-review.md` and told me `sudo` needs a password here, so it
couldn't install `gh` itself — it gave me the two commands to run.

**Verdict:** accepted, with one thing to watch — see Reflection, item 3.

---

## 4. The main implementation prompt

> so we need to work on this branch work/week8, all the requirements and big picture are in the requirements_week8.md, we don not need to dublicate the logic on OpenGraph, we only need to reuse it.
> ### You are an expert programmer in ruby with 10 years expirence in ruby on rails. this project is based on old_req.md. your scope is to implement a clean aproache on this project. rspec tests for everithing first and then to update the logic of the program. please work on small commits in this work/week8 only. small and lisible commits so in case of failure we can go back an fix the real problem.
> we need to follow the SOLID prinpicles + tests with TDD aproche.
> for this project the new thing where OpenGraph and GraphQL but now we need to do the project part of requirements_week8.md.
> ### please analize the prokect and keep implement it in small commits (tests first in rspec then update the logic) in case someting failes take a stepp back and analize the big picture before rushing to fix the problem.

**What came back:** This did the most work of any prompt in the session. Claude invoked
`feature-development`, read both requirement documents, read the whole app, ran the suite to
record a green baseline (14 examples, 0 failures), and produced a spec with seven numbered
acceptance criteria plus an eight-step red/green plan.

The important thing it surfaced during exploration — the thing the exercise is actually testing:

> `UrlExtractor` and `OpenGraphExtractor` are already reusable service objects — but the
> **orchestration** that ties them together isn't. It's inline in
> `app/graphql/mutations/tweet_create.rb:14-27`. Copying that loop into `CommentCreate` is
> exactly the duplication the requirements warn about, and it's the path of least resistance.

It also identified that `Resource belongs_to :tweet` blocks the whole feature and proposed a
polymorphic association, listing two rejected alternatives with reasons. Then it stopped and
waited for approval instead of writing code.

**Verdict:** accepted. No re-prompt needed.

---

## 5. Persist the plan and start building

> keep this plan in a plan.md (we can modify it on the go) file so we can revisit it anytime in case we are stuck. this will be our direction. let's implement the rquirements

**What came back:** Wrote `plan.md`, then implemented all eight steps test-first, committing
after each green. 12 checkpoint commits, suite 14 → 26 examples.

Notable moments:

- **It caught itself over-implementing.** After the first green, two follow-up tests passed
  immediately with no red phase. Rather than counting them as TDD cycles, it said so, then
  deleted the `next unless metadata` guard from the source and re-ran to prove the test actually
  failed without it. It did have teeth.
- **The plan was wrong about blast radius and it said so.** The plan predicted only
  `resource_spec.rb` would need updating for the polymorphic change; `tweet_spec.rb` and
  `tweet_create_spec.rb` also broke. It updated `plan.md` to record the miss rather than quietly
  fixing it.
- **The N+1 was measured, not asserted.** The failing test reported `expected: 4, got: 14`
  before the fix.
- **It verified against a running app**, not just the suite — booted Rails on port 3009 and made
  real network Open Graph fetches against `github.com` and `ruby-lang.org`, then read
  `log/development.log` to confirm the SQL was batched (`comments.tweet_id IN (1, 2, 3, 4)`).

**Verdict:** accepted.

---

## 6. Commit the supporting files

> as long as in the commits there is no sensitive data we can commit it

**What came back:** Ran a secret scan over the files before committing, confirmed
`config/master.key` is untracked (only the encrypted `credentials.yml.enc`, pre-existing), and
committed `plan.md`, `.claude/rules/`, and both requirement documents.

**Verdict:** accepted.

---

## 7. Review the branch

*(Ran `code-review` as the hand-off step of `feature-development`.)*

**What came back:** A structured review at **High** risk. It found the dropped foreign key on
`resources`, the untimed/SSRF-exposed outbound fetch, the over-fetching `includes`, and the two
error channels in `CommentCreate`. It also empirically confirmed the rollback destroys comment
resources by actually running `db:rollback` and observing resources go 5 → 4, rather than
reasoning about it from the migration source.

**Verdict:** accepted.

---

## 8. This file

> draft the PROMPTS.md from the session transcript

**Verdict:** accepted — with the reflection below rewritten in my own words before submitting.

---

## Reflection

> **Note:** this section is drafted from what the transcript shows. The judgment calls —
> what I'd have rejected, what I'd trust next time — need to be in my own words before I
> submit this.

**Which prompt did the most work.** Prompt 4, by a wide margin. Loading the requirements, the
role, the constraints (SOLID, TDD, small commits) and the explicit "reuse, don't duplicate"
instruction in one message meant the plan came back already shaped correctly — including the
observation that the reusable part wasn't the service objects but the orchestration between
them. Everything after that was execution against a plan I'd already approved. The single most
valuable line was *"in case someting failes take a stepp back and analize the big picture before
rushing to fix the problem"* — that framing is why the polymorphic migration got an
add-backfill-drop design instead of a rename.

**Where I had to step in.** Less than the exercise expects, which is itself worth noting — I did
not reject a single output outright. My interventions were all directional rather than
corrective:

1. Choosing to stay on `work/week8` instead of letting it cut a `feature/` branch.
2. Asking for the plan to be persisted to `plan.md` — this turned out to matter, because Claude
   then kept it updated with what it got *wrong* (the blast-radius miss in step 2).
3. Overruling the configured "checkpoint + curate" setting to keep all 12 commits. Claude
   surfaced the conflict between my setup answer and my stated bisect preference instead of
   silently squashing, and recommended keeping them.
4. Confirming the commit-the-docs decision after a secret scan.

**What I'd put in `CLAUDE.md` so I wouldn't have to say it again.** Everything I repeated in
prompt 4 that is really a standing project rule:

- Test-first with RSpec; one failing test at a time; confirm genuine red before implementing.
- Business logic lives in `app/services/` or models — GraphQL mutations and resolvers stay thin.
- Before adding a service, search for an existing one that does the job. Never a second copy of
  an extraction pipeline.
- Outbound HTTP needs a timeout and must be stubbed in specs, never live.
- Small, individually-green commits; don't squash without asking.
- Run `bundle exec rspec` and `bin/rubocop` before declaring anything done.

Most of these ended up in `.claude/rules/` during setup instead, which works — but `CLAUDE.md`
is where they belong for anyone not using these two skills.

**What Claude got wrong that I almost merged anyway.** The **dropped foreign key**. Making
`Resource` polymorphic silently removed `add_foreign_key "resources", "tweets"` from the schema —
the database no longer prevents orphaned resources, and only an app-level `dependent: :destroy`
stands in for it. That constraint had been there since the table was created. The plan called
step 2 "the risky one" but framed the risk as *migration mechanics on SQLite*, not as *you are
giving up referential integrity*. All 26 tests pass either way, so nothing in the suite would
have caught it. It only surfaced in the review, at the very end, and if I'd skipped the review
step it would have gone in unnoticed.

Two smaller ones in the same category:

- During `code-review` setup, one of the four questions went unanswered and Claude filled in all
  four proposed conventions on its own. It said so in the summary — but a faster read would have
  missed that config I never actually chose is now enforced on every review.
- The first implementation of `ResourceExtractor` included a nil-guard no test had asked for.
  Two later tests then passed on arrival. Claude flagged this and proved the guard was load-bearing
  by deleting it, but the same pattern with a *wrong* guard would produce tests that look like
  TDD cycles and verify nothing.

The pattern across all three: the failures weren't in the code Claude wrote, they were in what it
**didn't say loudly enough** about the code it wrote. The output was correct; the framing
undersold the consequence. Reading the diff is what caught it, exactly as the brief said it would.
