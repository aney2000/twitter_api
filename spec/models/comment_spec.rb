require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    it 'is invalid without content' do
      comment = Comment.new(content: nil)

      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("can't be blank")
    end
  end

  describe 'uuid generation' do
    it 'generates a uuid when created' do
      comment = Comment.create!(tweet: Tweet.create!(content: 'A tweet'), content: 'A comment')

      expect(comment.uuid).to be_present
      expect(comment.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end
  end

  describe 'associations' do
    it 'can have many resources of its own' do
      comment = Comment.create!(tweet: Tweet.create!(content: 'A tweet'), content: 'A comment')
      resource = comment.resources.create!(url: 'https://12ft.io/')

      expect(comment.resources).to include(resource)
      expect(resource.resourceable).to eq(comment)
    end
  end
end
