# Week 8 — Tweet Comments

Working plan for `requirements_week8.md`. Living document: update it as things change.
Branch: `work/week8` (no feature branch — see `.claude/rules/feature-development.md`).

Baseline before any change: **14 examples, 0 failures**.

---

## Problem

The API supports tweets with Open Graph resources but has no notion of a comment.
Add commenting on a tweet, reusing the same URL-scan → Open Graph → persist pipeline, and
expose comments through the existing `tweets` query.

## Acceptance criteria

1. `commentCreate(input: { tweetUuid, content })` creates a comment on the tweet with that
   uuid and returns `comment { uuid }`.
2. The comment's content is scanned for URLs and the Open Graph metadata is saved as that
   comment's resources.
3. `commentCreate` with an unknown `tweetUuid` returns a GraphQL **error** — `data.commentCreate`
   is null and no comment is created. Not a comment with null fields.
4. The `tweets` query exposes `comments { uuid message resources { title description url image { url } } }`.
5. Existing tweet behaviour is unchanged — `tweetCreate` and `tweets { resources }` still pass
   their current specs.
6. `tweets` fires a constant number of SQL queries regardless of how many tweets and comments exist.
7. Exactly **one** implementation of the scan-URLs → fetch-OG → persist-resources pipeline exists
   in the codebase, used by both mutations.

## Out of scope

Editing/deleting comments, replies-to-comments, auth, pagination, and computing a real
`image.byteSize` (stays `0`, as today).

---

## Key findings from exploration

- `UrlExtractor` and `OpenGraphExtractor` are already reusable — but the **orchestration**
  that ties them together is inline in `app/graphql/mutations/tweet_create.rb`. Copying that
  loop into `CommentCreate` is the duplication the requirements warn about. Extract it first.
- `Resource belongs_to :tweet` with a non-null FK. A comment cannot own a resource until that
  association becomes polymorphic.
- `Tweet#generate_uuid` will be duplicated by `Comment` — extract to a shared concern.

---

## Steps

Each step is a red/green pair; checkpoint-commit after each green.

- [x] **1. Extract the pipeline** *(behaviour-preserving refactor)* — done, 17 examples green
      Prove: `ResourceExtractor.call(record)` creates a resource per URL in `record.content`;
      none when there are no URLs; none when the OG fetch returns `nil`.
      Implement: `app/services/resource_extractor.rb`; `TweetCreate` delegates to it.
      The existing `tweetCreate` spec staying green proves no behaviour change.

- [x] **2. Resource becomes polymorphic** — done; `spec/models/tweet_spec.rb` also needed updating
      (it used `Resource.create!(tweet:)`), not just `resource_spec.rb` as predicted
      Prove: a `Resource` belongs to a polymorphic `resourceable`; `tweet.resources` still works.
      Implement: migration adding `resourceable_id`/`resourceable_type`, backfilling from
      `tweet_id`, then dropping `tweet_id`; update `Resource` and `Tweet`.

- [x] **3. Comment model** — done; uuid concern is `GeneratesUuid`
      Prove: a comment requires content, belongs to a tweet, gets a uuid on create, has many resources.
      Implement: migration + `app/models/comment.rb`; extract uuid generation into a shared concern.

- [x] **4. `commentCreate` happy path** — done
      Prove: the mutation creates a comment on the given tweet and returns its uuid.
      Implement: `Types::CommentType`, `Mutations::CommentCreate`, wired into `MutationType`.

- [x] **5. `commentCreate` extracts resources** — done, one line: `ResourceExtractor.call(comment)`
      Prove: a comment whose content contains a URL gets a resource with the OG metadata
      attached to *the comment*.
      Implement: call `ResourceExtractor` from the mutation — the same service `TweetCreate` uses.

- [x] **6. Unknown tweet is an error** — done
      Prove: commenting on a non-existent `tweetUuid` returns a GraphQL error,
      `data.commentCreate` is null, and no comment row is created.
      Implement: raise `GraphQL::ExecutionError`.

- [x] **7. `tweets` exposes comments** — done
      Prove: the `tweets` query returns each tweet's comments with uuid, message and resources.
      Implement: `field :comments` on `TweetType`.

- [x] **8. Kill the N+1** — done; measured 14 queries → 4, constant
      Prove: a spec counting SQL queries — 3 tweets × 3 comments each fires the same number of
      queries as 1 tweet × 1 comment.
      Implement: eager-load in `QueryType#tweets`.

---

## Alternatives rejected

- **Nullable `comment_id` alongside `tweet_id` on resources** — makes invalid states
  representable (both set, neither set) and forces branching inside the extractor.
- **A second copy of the OG loop in `CommentCreate`** — the explicit anti-goal of the exercise.
- **`GraphQL::Dataloader` sources instead of `includes`** — more precise fetching, meaningfully
  more machinery. `includes` satisfies criterion 6 with far less code. Revisit if the schema grows.

## Risks

- **Step 2 is the risky one.** It rewrites a table that has an existing foreign key, on SQLite.
  Use add-backfill-drop rather than rename, so each stage is reversible.
- **`spec/models/resource_spec.rb` will be modified** in step 2 — it currently asserts
  `belongs_to :tweet`. A real contract change to shared code, flagged deliberately.
- The N+1 spec needs a query-counting helper; no gem available, so add a small
  `spec/support` subscriber.

## Not mine to write

`PROMPTS.md` and `CLAUDE.md` are required by `requirements_week8.md` but are the author's
deliverables — the prompt log and reflection can't be reconstructed after the fact.

---

## Progress log

- Baseline recorded: 14 examples, 0 failures.
- All 8 steps implemented. Suite: **26 examples, 0 failures**.
- `bin/rubocop` clean (65 files), `bin/brakeman` 0 warnings, `bin/bundler-audit` 0 vulnerabilities.
- Verified against the running app on port 3009 with real network Open Graph fetches:
  tweet + comment created, unknown-uuid returns `"Tweet not found"` with `data.commentCreate: null`,
  full nested query returns comments with their own resources, and the dev log shows
  **4 SQL loads** for 4 tweets (`comments.tweet_id IN (1, 2, 3, 4)` — batched, not per-tweet).
- Pipeline call sites confirmed: `ResourceExtractor` is the only caller of
  `UrlExtractor`/`OpenGraphExtractor`; both mutations call it. Criterion 7 holds.
