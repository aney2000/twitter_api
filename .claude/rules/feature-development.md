# Feature Development — project settings

Non-default choices for the `feature-development` skill. Anything not listed here uses the
skill's defaults (inline spec note, Solo AI test loop, checkpoint + curate commits).

## Branching

**Do not create a branch when starting a feature or bug fix.** Work continues on whatever
branch is currently checked out (`work/weekN`). This overrides the skill's default of
branching `feature/<slug>` from `main`.

Consequence for hand-off: commit curation rewrites history on a branch that may already be
pushed. Reshape only local, un-pushed checkpoints; never force-push without asking.

## Review hand-off

The `code-review` skill is installed — delegate the structured self-review to it before
preparing the PR description.

## Verification

Full suite: `bin/rails db:test:prepare && bundle exec rspec`
Lint (CI-enforced): `bin/rubocop`
Security (CI-enforced): `bin/brakeman --no-pager` and `bin/bundler-audit`
