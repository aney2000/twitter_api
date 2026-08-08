module Mutations
  class CommentCreate < BaseMutation
    description "Creates a new comment on a tweet"

    argument :tweet_uuid, ID, required: true
    argument :content, String, required: true

    field :comment, Types::CommentType, null: true
    field :errors, [ String ], null: false

    def resolve(tweet_uuid:, content:)
      tweet = Tweet.find_by(uuid: tweet_uuid)
      comment = tweet.comments.new(content: content)

      if comment.save
        {
          comment: comment,
          errors: []
        }
      else
        {
          comment: nil,
          errors: comment.errors.full_messages
        }
      end
    end
  end
end
