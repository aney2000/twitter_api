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

    it 'keeps an explicitly assigned uuid instead of overwriting it' do
      tweet = Tweet.create!(content: 'My tweet', uuid: '1231-1231-1231-1231')

      expect(tweet.uuid).to eq('1231-1231-1231-1231')
    end
  end

  describe 'uuid uniqueness' do
    it 'is enforced at the database level' do
      existing = Tweet.create!(content: 'first')
      duplicate = Tweet.new(content: 'second', uuid: existing.uuid)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'content' do
    it 'is rejected as null at the database level' do
      tweet = Tweet.new(content: nil)

      expect { tweet.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe 'associations' do
    it 'can have many resources' do
      tweet = Tweet.create!(content: 'My tweet')
      resource1 = Resource.create!(resourceable: tweet, url: 'https://site1.com')
      resource2 = Resource.create!(resourceable: tweet, url: 'https://site2.com')

      expect(tweet.resources.count).to eq(2)
      expect(tweet.resources).to include(resource1, resource2)
    end
  end
end
