# Code Review — project settings

Project choices for the `code-review` skill. Anything not listed here uses the skill's
built-in behaviour (including the default output format and reply-and-resolve handling of
prior review threads).

## Context gathering

No issue tracker integration is configured. Use the PR title and description as the source
of truth for what problem the change is meant to solve. If the PR body is empty, ask the
author rather than inferring intent from the diff.

## Build verification

Do not take CI status on trust — run the checks locally before reviewing, and pause the
review if either fails:

```
bin/rails db:test:prepare && bundle exec rspec
bin/rubocop
```

CI additionally runs `bin/brakeman --no-pager` and `bin/bundler-audit`; run those too when
the diff touches request handling, external input, or the Gemfile.

## Posting mechanics

Reviews are posted to the GitHub PR via `gh` (repo: `aney2000/twitter_api`):

- Summary as a standalone PR comment, first line `<!-- code-review-summary -->`.
  On a re-review, delete the previous summary (found by that marker) before posting the new one.
- Each finding as an inline review comment on the relevant line, first line
  `<!-- code-review-finding -->`.
- Identify your own prior threads by these markers, never by the posting account.

If `gh` is unavailable or unauthenticated at review time, fall back to printing the review
in chat and say explicitly that prior review state could not be checked.

## Project-specific checks

- **Skip style nits already covered by `rubocop-rails-omakase`.** Formatting and style are
  enforced in CI; do not spend review budget on them.
- **GraphQL layering.** Mutations (`app/graphql/mutations/`) and resolvers stay thin —
  business logic belongs in `app/services/` or the model. Flag logic that leaks into the
  GraphQL layer.
- **N+1 queries.** Flag resolvers that load associations per record without batching,
  particularly nested fields such as `resources` under `tweets`.
- **Outbound HTTP safety.** Calls that fetch external URLs (e.g. `OpenGraphExtractor`) need
  explicit timeouts, error handling for non-200/malformed responses, and SSRF consideration
  since the URL originates in user-submitted tweet content. In specs, these calls must be
  stubbed — never hit the network.
