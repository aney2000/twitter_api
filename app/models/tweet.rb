class Tweet < ApplicationRecord
  include GeneratesUuid
  include Resourceable

  has_many :comments, dependent: :destroy

  validates :content, presence: true
end
