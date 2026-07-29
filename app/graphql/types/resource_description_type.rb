module Types
  class ResourceDescriptionType < Types::BaseObject
    field :title, String, null: false
    field :description, String, null: false
    field :url, String, null: false
    field :image, Types::ImageType, null: false
  end
end