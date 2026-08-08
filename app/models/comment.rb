class Comment < ApplicationRecord
  belongs_to :tweet

  validates :content, presence: true
end
