class Comment < ApplicationRecord
  include GeneratesUuid

  belongs_to :tweet

  has_many :resources, as: :resourceable, dependent: :destroy

  validates :content, presence: true
end
