class Resource < ApplicationRecord
  belongs_to :tweet

  validates :url, presence: true
end
