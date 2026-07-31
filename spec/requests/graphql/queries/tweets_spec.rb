require 'rails_helper'

RSpec.describe 'GraphQL Queries: tweets', type: :request do
  describe 'querying a list of tweets' do
    let!(:tweet) { Tweet.create!(content: 'Check this out: https://12ft.io/') }

    let!(:resource) do
      tweet.resources.create!(
        title: '12ft - Hop any paywall',
        description: 'Show me a 10ft paywall',
        url: 'https://12ft.io/',
        image_url: 'https://12ft.io/og-banner.png'
      )
    end

    let(:query) do
      <<~GQL
        query {
          tweets {
            uuid
            message
            resources {
              title
              description
              url
              image {
                url
                byteSize
              }
            }
          }
        }
      GQL
    end

    it 'returns all tweets with their mapped resources' do
      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['tweets']

      expect(response).to have_http_status(:ok)

      first_tweet = data.first
      expect(first_tweet['uuid']).to eq(tweet.uuid)
      expect(first_tweet['message']).to eq('Check this out: https://12ft.io/')

      first_resource = first_tweet['resources'].first
      expect(first_resource['title']).to eq('12ft - Hop any paywall')
      expect(first_resource['description']).to eq('Show me a 10ft paywall')
      expect(first_resource['url']).to eq('https://12ft.io/')

      expect(first_resource['image']['url']).to eq('https://12ft.io/og-banner.png')
      expect(first_resource['image']['byteSize']).to eq(0)
    end
  end
end
