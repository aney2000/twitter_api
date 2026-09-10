class Comment < ApplicationRecord
  include GeneratesUuid
  include Resourceable

  belongs_to :tweet

  validates :content, presence: true
end
