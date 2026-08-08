class Tweet < ApplicationRecord
  has_many :resources, as: :resourceable, dependent: :destroy

  validates :content, presence: true

  before_create :generate_uuid

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end
