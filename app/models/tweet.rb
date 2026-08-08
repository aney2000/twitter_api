class Tweet < ApplicationRecord
  include GeneratesUuid

  has_many :resources, as: :resourceable, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :content, presence: true
end
