module Mutations
  class TweetCreate < BaseMutation
    description "Creates a new tweet"

    argument :content, String, required: true

    field :tweet, Types::TweetType, null: true
    field :errors, [ String ], null: false

    def resolve(content:)
      tweet = Tweet.new(content: content)

      if tweet.save
        ResourceExtractor.call(tweet)

        {
          tweet: tweet,
          errors: []
        }
      else
        {
          tweet: nil,
          errors: tweet.errors.full_messages
        }
      end
    end
  end
end
