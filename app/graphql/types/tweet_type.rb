module Types
  class TweetType < Types::BaseObject
    field :uuid, ID, null: false
    field :message, String, null: false, method: :content

    field :resources, [ Types::ResourceDescriptionType ], null: false
    field :comments, [ Types::CommentType ], null: false
  end
end
