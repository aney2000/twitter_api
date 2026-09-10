# Prompt History — Week 8, Tweet Comments

Chronological log of every prompt used to build the comments feature, what came back, and the
verdict. Drafted from the session transcript.

---

## 1. Add the skills marketplace

> /plugin marketplace add agilefreaks/claude-skills

**What came back:** `Successfully added marketplace: agilefreaks-skills`.

**Verdict:** accepted.

---

## 2. Install feature-development

> /plugin install feature-development@agilefreaks-skills

**What came back:** Installed and active.

**Verdict:** accepted.

---

## 3. Install code-review

> /plugin install code-review@agilefreaks-skills

**What came back:** Installed and active.

**Verdict:** accepted.

---

## 4. Set up the feature-development skill

> set up feature-development

**What came back:** Claude scanned the project first — found no `CLAUDE.md` and no
`.claude/rules/`, identified RSpec with specs split into `models/`, `services/` and
`requests/graphql/`, read `.github/workflows/ci.yml` for the real commands, and noticed the
de-facto `work/weekN` branch pattern with nothing documenting it. Then asked four questions:
branching, spec capture, test-collaboration mode, commit granularity.

Answers: **stay on the current branch**, inline spec note, **Solo AI**, checkpoint + curate.

It wrote `.claude/rules/feature-development.md` with only the one non-default choice, and
flagged a consequence I hadn't considered: staying on a shared branch means commit curation
would rewrite history that might already be pushed.

**Verdict:** accepted. Solo AI was required by the brief — the other modes have the human
writing assertions, which this exercise doesn't allow.

---

## 5. Set up the code-review skill

> set up code-review

**What came back:** Detected `gh` was not installed, which constrains everything — no PR
reading, no posting, no CI status. Asked four questions: review delivery, build verification,
project conventions, CI workflow.

Answers: **post to PR (install `gh`)**, **run checks locally**, *(conventions left unanswered)*,
**skip the CI workflow**.

Wrote `.claude/rules/code-review.md`. Told me `sudo` needs a password here so it couldn't
install `gh` itself.

**Verdict:** accepted — with one thing to watch, see Reflection.

---

## 6. The main implementation prompt

> so we need to work on this branch work/week8, all the requirements and big picture are in the requirements_week8.md, we don not need to dublicate the logic on OpenGraph, we only need to reuse it.
> ### You are an expert programmer in ruby with 10 years expirence in ruby on rails. this project is based on old_req.md. your scope is to implement a clean aproache on this project. rspec tests for everithing first and then to update the logic of the program. please work on small commits in this work/week8 only. small and lisible commits so in case of failure we can go back an fix the real problem.
> we need to follow the SOLID prinpicles + tests with TDD aproche.
> for this project the new thing where OpenGraph and GraphQL but now we need to do the project part of requirements_week8.md.
> ### please analize the prokect and keep implement it in small commits (tests first in rspec then update the logic) in case someting failes take a stepp back and analize the big picture before rushing to fix the problem.

**What came back:** The most productive prompt of the session. Claude invoked
`feature-development`, read both requirement documents, read the whole app, ran the suite for a
green baseline (14 examples, 0 failures), and produced seven numbered acceptance criteria plus
an eight-step red/green plan.

The thing it surfaced during exploration — what the exercise is actually testing:

> `UrlExtractor` and `OpenGraphExtractor` are already reusable service objects — but the
> **orchestration** that ties them together isn't. It's inline in
> `app/graphql/mutations/tweet_create.rb:14-27`. Copying that loop into `CommentCreate` is
> exactly the duplication the requirements warn about, and it's the path of least resistance.

It also identified that `Resource belongs_to :tweet` blocks the feature entirely, proposed a
polymorphic association, listed two rejected alternatives with reasons, then stopped and waited
for approval instead of writing code.

**Verdict:** accepted. No re-prompt needed.

---

## 7. Persist the plan and start building

> keep this plan in a plan.md (we can modify it on the go) file so we can revisit it anytime in case we are stuck. this will be our direction. let's implement the rquirements

**What came back:** Wrote `plan.md`, then implemented all eight steps test-first, committing
after each green. 12 checkpoint commits, suite 14 → 26 examples.

Notable moments:

- **It caught itself over-implementing.** After the first green, two follow-up tests passed
  immediately with no red phase. Rather than counting them as TDD cycles it said so, then
  deleted the `next unless metadata` guard from the source and re-ran to prove the test failed
  without it.
- **The plan was wrong about blast radius and it said so.** It predicted only
  `resource_spec.rb` would need updating for the polymorphic change; `tweet_spec.rb` and
  `tweet_create_spec.rb` also broke. It recorded the miss in `plan.md` rather than quietly
  fixing it.
- **The N+1 was measured, not asserted** — `expected: 4, got: 14` before the fix.
- **It verified against a running app**, booting Rails on port 3009 with real network Open Graph
  fetches, then reading `log/development.log` to confirm batching
  (`comments.tweet_id IN (1, 2, 3, 4)`).

It then ran `code-review` as the hand-off step, which produced the seven findings that later
went onto the PR.

**Verdict:** accepted.

---

## 8. Commit the supporting files

> as long as in the commits there is no sensitive data we can commit it

**What came back:** Ran a secret scan first, confirmed `config/master.key` is untracked (only
the encrypted `credentials.yml.enc`, pre-existing), then committed `plan.md`, `.claude/rules/`,
and both requirement documents.

**Verdict:** accepted.

---

## 9. Draft this file

> draft the PROMPTS.md from the session transcript

**What came back:** Eight entries plus a Reflection, with a visible note that the reflection
needed rewriting in my own words. It flagged unprompted that every verdict was "accepted",
and that a log of eight straight acceptances invites a question in review.

**Verdict:** accepted.

---

## 10. Commit it

> commit it

**What came back:** Committed as `ca1e490`. Then listed what was left: CI unrun, reflection not
in my words, no `CLAUDE.md`, two tickets worth filing.

**Verdict:** accepted.

---

## 11. Add a CLAUDE.md

> add a CLAUDE.md with the project rules

**What came back:** Wrote `CLAUDE.md` covering commands, architecture, the three-service Open
Graph pipeline (with the explicit "make your record `resourceable`, don't write a second loop"
rule), test conventions, GraphQL gotchas, and a "Known gaps" section listing the four deferred
issues.

It deliberately did **not** duplicate the skill config from `.claude/rules/` — project
description in one place, skill behaviour in the other — and pointed out this made a paragraph
of my `PROMPTS.md` reflection stale.

**Verdict:** accepted.

---

## 12. First completeness audit

> is there anything left for me to do in the requirements_week8.md ? besides What we'll talk about in review section which is clear that I will need to talk with the reviewer ? is everithing implemented ? is the code 100% testable ? is clean enough to respect SOLID principles ? we missed something ?

**What came back:** Verified against the *generated* schema (`TwitterApiSchema.to_definition`)
rather than from memory. Confirmed requirements met, with two harmless deltas (non-null list
elements, `clientMutationId`). Then answered the harder parts honestly rather than
reassuringly: **not** 100% testable (`OpenGraphExtractor` needs `allow_any_instance_of` and
global `URI` stubbing), and SOLID is **partial** — SRP and OCP respected, **DIP is not**, with
the constant-stubbing in every spec as the evidence.

**Verdict:** accepted. This is the answer I'd have wanted a colleague to give.

---

## 13. Install gh

> first help me install gh so we can test it by code-review

**What came back:** Checked `apt-cache policy` and `snap info` without sudo, offered the
one-line apt install (v2.45) or GitHub's own repo (v2.8x), and advised against snap under WSL2
since snapd needs systemd.

**Verdict:** accepted.

---

## 14. Pasted the command as a message

> sudo apt-get install -y gh

**What came back:** Claude tried `sudo -n` to be sure, got `sudo: a password is required`, and
explained that pasting the command sends it as text — it needs the `!` prefix to actually run.

**Verdict:** re-prompted.

---

## 15. Ran it with the `!` prefix

> ! sudo apt-get install -y gh

**What came back:** Also failed —
`sudo: a terminal is required to read the password`. The `!` prefix runs in the session's
shell, which has no TTY for a password prompt either. **Two suggestions in a row that couldn't
work.**

**Verdict:** re-prompted. See Reflection.

---

## 16. Rejected: the no-sudo workaround

*(Claude proposed installing the `gh` static binary into `~/.local/bin` to sidestep sudo
entirely, and began checking architecture and `PATH`. I interrupted and denied the tool call.)*

**Verdict:** **rejected.** I didn't want a hand-rolled binary outside the package manager on my
machine; a normal terminal window solves it properly.

---

## 17. Installed it myself

> installed gh in another terminal windows please look for it

**What came back:** Found `/usr/bin/gh` v2.45.0, confirmed it wasn't authenticated yet, and gave
the `gh auth login` flow to run in the same terminal.

**Verdict:** accepted.

---

## 18. Verify, and do not merge

> ok lets verify with gh now. do not merge the pull request, I need to make a phisicle reviw first, only check it form code-review perspective

**What came back:** Auth still wasn't done, so it said so rather than pretending. Confirmed it
wouldn't merge — and noted merging was never on its list. Then raised something I hadn't
considered: four of the seven findings are on *pre-existing* code, and asked whether the PR
should carry them or keep them as tickets.

**Verdict:** accepted.

---

## 19. Continue with the review

> I set up the gh auth, please continue with the coe-review

**What came back:** Verified auth (`aney2000`), found the branch already pushed and **PR #6
already open**, checked for prior review threads (none), and noticed the PR body was empty and
the base was `work/week7` — confirming the base was the *right* choice, since against `main` the
diff would drag in 28 commits of week-7 work.

Filled the PR description, then posted the review: summary comment plus four inline findings,
each with hidden markers for future re-review tracking. Hit a `gh` 2.45 bug (`pr edit` calls
deprecated Projects-classic endpoints) and worked around it via the REST API.

Flagged a structural limit I hadn't thought about: **the most serious finding — SSRF/timeout —
can't be an inline comment**, because GitHub only allows those on lines present in the diff, and
that file is unchanged.

**Verdict:** accepted.

---

## 20. Confirming it was the first review

> this will be the first code-review

**What came back:** Matched what it had already found — no prior comments, reviews, or threads.
Nothing to reconcile.

**Verdict:** accepted.

---

## 21. Second completeness audit

*(Same text as entry 12, asked again after the PR went up.)*

**What came back:** Rather than repeating itself, it re-checked what had **changed** — CI now
green (lint, scan_ruby, test all pass) — and surfaced something new it had got wrong:
**`PROMPTS.md` was stale**, stopping at entry 8 and missing roughly nine prompts including the
entire `gh` sequence and the PR review itself.

**Verdict:** accepted.

---

## 22. Should we fix the minor things?

> if we are to corect this munor things, will the base logic changed ? is it better to do your updates or to keep this pull request as is ? please analize the requirements_week8.md one more time and plan this changes if they are nececary

**What came back:** Re-read the requirements, then recommended **keeping the code as is** and
fixing only `PROMPTS.md`. The argument that persuaded me: the brief's review section asks
*"What did `code-review` flag on your own PR before you handed it over?"* — silently fixing all
four findings destroys the answer. Flagged-and-deferred is the deliverable.

It also talked me out of matching the spec's `[Comment]!` literally, since our `[Comment!]!` is
strictly stricter and every query in the spec works against it.

**Verdict:** accepted.

---

## 23. Wrap up

> ok, thank you for explaining, so let's wrap it up for today, only Fix only PROMPTS.md if we don't have anything left in requirements_week8.md

**What came back:** This file.

**Verdict:** accepted.

---

## Reflection

> **Note:** drafted from the transcript. The judgment calls need to be in my own words before I
> submit.

**Which prompt did the most work.** Entry 6, by a wide margin. Loading the requirements, the
role, the constraints (SOLID, TDD, small commits) and the explicit "reuse, don't duplicate"
instruction in one message meant the plan came back already shaped correctly — including the
observation that the reusable part wasn't the service objects but the *orchestration between
them*. Everything after was execution against a plan I'd approved. The single most valuable
line was *"in case someting failes take a stepp back and analize the big picture before rushing
to fix the problem"* — that framing is why the polymorphic migration got an add-backfill-drop
design instead of a rename.

**Which prompts needed a retry, and what made the first one fail.** Entries 13–17, the `gh`
install. Claude suggested `sudo apt-get install -y gh`, then `! sudo apt-get install -y gh` when
that turned out to be a pasted message rather than a run command. **Both failed for the same
root cause** — no TTY to type a password into — and the second suggestion didn't account for
the failure mode of the first. It had already established "sudo needs a password" back in entry
5 and still proposed two routes that require one. The fix was mundane: I opened a normal
terminal. Worth noting the failure was environmental, not a misunderstanding of the task — but
a sharper first answer would have been *"this needs a real terminal, here's the command"*.

**What I rejected outright.** Entry 16 — the proposal to download the `gh` static binary into
`~/.local/bin` to bypass sudo. It would have worked, and Claude could have done it unattended.
I stopped it because I don't want package-manager-invisible binaries on my machine for a
convenience I could solve by opening another window. This is the only outright rejection in the
session, which is itself worth noticing: across 23 prompts I re-prompted twice and rejected
once. Either the prompting was well-targeted or I wasn't being critical enough — see below.

**What I'd put in `CLAUDE.md` so I wouldn't have to say it again.** I did write it (entry 11).
The rules that came straight out of what I'd repeated in entry 6: test-first, one failing test
at a time, confirm genuine red; business logic in `app/services/` with thin GraphQL mutations;
search before adding a service; outbound HTTP needs timeouts and must be stubbed in specs;
small individually-green commits; run the suite and rubocop before calling anything done. The
split I settled on: `CLAUDE.md` describes the *project*, `.claude/rules/` describes how the two
skills operate on it — duplicating between them means they drift.

**What Claude got wrong that I almost merged anyway.** The **dropped foreign key**. Making
`Resource` polymorphic silently removed `add_foreign_key "resources", "tweets"` — the database
no longer prevents orphaned resources, and only an app-level `dependent: :destroy` stands in for
it. That constraint had existed since the table was created. The plan called step 2 "the risky
one" but framed the risk as *SQLite migration mechanics*, not *you are giving up referential
integrity*. **All 26 tests pass either way**, so nothing in the suite would have caught it. It
surfaced only in the review, at the very end — and if I'd skipped the review step it would have
gone in unnoticed.

Two smaller ones in the same family:

- During `code-review` setup (entry 5), one of four questions went unanswered and Claude filled
  in all four proposed conventions itself. It said so in the summary — but a faster read would
  have missed that config I never chose is now enforced on every review.
- The first `ResourceExtractor` included a nil-guard no test had asked for (entry 7). Two later
  tests then passed on arrival. Claude flagged this and proved the guard was load-bearing by
  deleting it — but the same pattern with a *wrong* guard produces tests that look like TDD
  cycles and verify nothing.

The pattern across all three: the failures weren't in the code Claude wrote, they were in what
it **didn't say loudly enough** about the code it wrote. The output was correct; the framing
undersold the consequence. Reading the diff is what caught it, exactly as the brief said it
would.
