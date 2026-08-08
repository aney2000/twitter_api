class Comment < ApplicationRecord
  include GeneratesUuid

  belongs_to :tweet

  validates :content, presence: true
end
