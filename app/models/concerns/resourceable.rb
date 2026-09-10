module Resourceable
  extend ActiveSupport::Concern

  included do
    has_many :resources, as: :resourceable, dependent: :destroy
  end
end
