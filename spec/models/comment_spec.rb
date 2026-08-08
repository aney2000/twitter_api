require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    it 'is invalid without content' do
      comment = Comment.new(content: nil)

      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("can't be blank")
    end
  end
end
