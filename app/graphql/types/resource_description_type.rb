module Types
  class ResourceDescriptionType < Types::BaseObject
    field :title, String, null: true
    field :description, String, null: true
    field :url, String, null: false
    field :image, Types::ImageType, null: false

    def image
      {
        url: object.image_url || "",
        byteSize: 0
      }
    end
  end
end
