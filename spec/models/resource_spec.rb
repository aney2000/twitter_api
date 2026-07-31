require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe 'associations' do
    it 'belongs to a tweet' do
      tweet = Tweet.create!(content: "Test")
      resource = Resource.new(
        tweet: tweet, 
        title: "Test Title", 
        url: "https://example.com"
      )
      expect(resource.tweet).to eq(tweet)
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