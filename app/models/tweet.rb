class Tweet < ApplicationRecord
  include GeneratesUuid

  has_many :resources, as: :resourceable, dependent: :destroy

  validates :content, presence: true
end
