# Twitter API

A GraphQL API for posting tweets and commenting on them. Any URL in a tweet or comment is
scanned, its Open Graph metadata fetched, and stored as a `Resource` for later querying.

Ruby 4.0.5 · Rails 8.1 · SQLite · graphql-ruby 2.6 · RSpec

Requirements live in `old_req.md` (tweets) and `requirements_week8.md` (comments).

## Commands

```bash
bin/rails db:test:prepare && bundle exec rspec   # full suite
bundle exec rspec path/to/file_spec.rb           # one file
bin/rubocop                                      # lint (CI-enforced)
bin/brakeman --no-pager                          # security scan (CI-enforced)
bin/bundler-audit                                # gem CVE scan (CI-enforced)
bin/rails server                                 # app on :3000, POST to /graphql
```

Run the suite and `bin/rubocop` before calling any change done. CI runs all five.

## Architecture

```
app/graphql/mutations/   thin — parse args, load records, delegate, shape the response
app/graphql/types/       field definitions; presentation-only logic
app/services/            business logic, plain classes with a `.call` class method
app/models/              persistence, associations, validations
app/models/concerns/     behaviour shared across models
```

**Keep mutations and resolvers thin.** Business logic belongs in a service or a model. A
mutation that grows a loop or a branch beyond error-shaping is a service waiting to be
extracted.

### The Open Graph pipeline

Three services compose, each with one job:

- `UrlExtractor.call(text)` → array of URLs
- `OpenGraphExtractor.call(url)` → metadata hash, or `nil` if the fetch fails
- `ResourceExtractor.call(record)` → orchestrates the two above and persists `Resource` rows
  against any record that `has_many :resources, as: :resourceable`

**`ResourceExtractor` is the only caller of the other two.** Both `TweetCreate` and
`CommentCreate` call it in one line. If you are adding Open Graph handling to a new record
type, make it `resourceable` and call `ResourceExtractor` — do not write a second copy of
the loop.

### Data model

- `Tweet has_many :resources, as: :resourceable` and `has_many :comments`
- `Comment belongs_to :tweet`, `has_many :resources, as: :resourceable`
- `Resource belongs_to :resourceable, polymorphic: true` — so any record can own resources
- `GeneratesUuid` concern gives a model a `uuid` on create; both `Tweet` and `Comment` include it

## Conventions

**Test first, one test at a time.** Write a single failing spec, confirm it fails *for the
right reason*, implement the minimum to pass, then move on. Never write several specs up
front. If a new spec passes on arrival, stop — either the behaviour already exists or the
spec asserts nothing. Prove it has teeth by breaking the code it covers.

**Test at the lowest level that proves the behaviour.** Specs mirror the source tree:

```
spec/models/            validations, associations, callbacks
spec/services/          service objects in isolation
spec/requests/graphql/  mutations and queries end-to-end through POST /graphql
spec/support/           shared helpers, auto-loaded into every run
```

**Never let a spec hit the network.** Stub `OpenGraphExtractor.call` with the URL you expect,
or stub `URI.open` when testing the extractor itself.

**Search before adding a service.** Duplicating an existing pipeline is the failure mode this
codebase is most prone to.

**Small, individually-green commits.** Each commit passes its own tests so `git bisect` stays
useful. Don't squash without asking.

## GraphQL notes

- `BaseMutation` is a `RelayClassicMutation` — arguments are wrapped in an `input` object, and
  snake_case arguments are exposed as camelCase (`tweet_uuid` → `tweetUuid`).
- A missing referenced record is a `GraphQL::ExecutionError`, not a payload with null fields.
  The `errors` field on a mutation payload is for validation failures only.
- Records are addressed publicly by `uuid`, never by database id.
- **Watch for N+1.** `QueryType#tweets` eager-loads with
  `Tweet.includes(:resources, comments: :resources)`. Any new nested association needs the same
  treatment. `spec/requests/graphql/queries/tweets_spec.rb` has a query-counting spec that
  fails if this regresses — use `count_queries` from `spec/support/query_counter.rb`.

## Known gaps

Pre-existing, deliberately not fixed as part of feature work. Worth a ticket, not a drive-by fix:

- **`OpenGraphExtractor` has no timeout and no host allowlist.** It calls `URI.open` on
  user-submitted URLs, so a slow host hangs the request and internal addresses are reachable
  (SSRF). `rescue StandardError` catches failures but not slowness.
- **Metadata is fetched synchronously inside the mutation.** A post with three URLs makes three
  blocking HTTP calls before responding. A background job is the usual answer.
- **No database-level foreign key on `resources`.** Polymorphic associations can't carry one;
  only `dependent: :destroy` prevents orphans, and that is bypassed by `delete_all` or raw SQL.
- **`tweets.uuid` is indexed but not uniquely**, unlike `comments.uuid`.
