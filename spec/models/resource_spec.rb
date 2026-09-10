require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe 'associations' do
    it 'belongs to a polymorphic resourceable' do
      tweet = Tweet.create!(content: "Test")
      resource = Resource.new(
        resourceable: tweet,
        title: "Test Title",
        url: "https://example.com"
      )
      expect(resource.resourceable).to eq(tweet)
    end

    it 'is still reachable through the owning tweet' do
      tweet = Tweet.create!(content: "Test")
      resource = tweet.resources.create!(url: "https://example.com")

      expect(tweet.resources).to include(resource)
    end
  end

  describe 'validations' do
    it 'is invalid without a url' do
      resource = Resource.new(url: nil)
      expect(resource).not_to be_valid
      expect(resource.errors[:url]).to include("can't be blank")
    end
  end
end
