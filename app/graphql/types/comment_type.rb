module Types
  class CommentType < Types::BaseObject
    field :uuid, ID, null: false
    field :message, String, null: false, method: :content

    field :resources, [ Types::ResourceDescriptionType ], null: false
  end
end
