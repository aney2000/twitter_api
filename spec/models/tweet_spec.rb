require 'rails_helper'

RSpec.describe Tweet, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      tweet = Tweet.new(content: 'This is a test: https://12ft.io')
      expect(tweet).to be_valid
    end

    it 'is not valid without content' do
      tweet = Tweet.new(content: nil)
      expect(tweet).not_to be_valid
      expect(tweet.errors[:content]).to include("can't be blank")
    end
  end

  describe 'callbacks' do
    it 'automatically generates a UUID before creation' do
      tweet = Tweet.create!(content: 'My first tweet')

      expect(tweet.uuid).to be_present
      expect(tweet.uuid).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end
  end

  describe 'associations' do
    it 'can have many resources' do
      tweet = Tweet.create!(content: 'My tweet')
      resource1 = Resource.create!(tweet: tweet, url: 'https://site1.com')
      resource2 = Resource.create!(tweet: tweet, url: 'https://site2.com')

      expect(tweet.resources.count).to eq(2)
      expect(tweet.resources).to include(resource1, resource2)
    end
  end
end
