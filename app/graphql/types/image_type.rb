module Types
  class ImageType < Types::BaseObject
    field :url, String, null: false
    field :byteSize, Integer, null: false
  end
end