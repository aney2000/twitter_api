require 'rails_helper'

RSpec.describe 'GraphQL Mutations: tweetCreate', type: :request do
  describe 'creating a tweet' do
    let(:mutation) do
      <<~GQL
        mutation($input: TweetCreateInput!) {
          tweetCreate(input: $input) {
            tweet {
              uuid
            }
          }
        }
      GQL
    end

    let(:variables) do
      {
        input: {
          content: 'Best thing I found in a while: https://12ft.io/'
        }
      }
    end

    before do
      allow(OpenGraphExtractor).to receive(:call).with('https://12ft.io/').and_return({
        title: '12ft - Hop any paywall',
        description: 'Show me a 10ft paywall',
        url: 'https://12ft.io/',
        image_url: 'https://12ft.io/og-banner.png'
      })
    end

    it 'creates a new tweet and its associated resources' do
      expect {
        post '/graphql', params: { query: mutation, variables: variables }
      }.to change(Tweet, :count).by(1)
       .and change(Resource, :count).by(1)

      json = JSON.parse(response.body)
      data = json.dig('data', 'tweetCreate', 'tweet')

      expect(response).to have_http_status(:ok)
      expect(data['uuid']).to be_present

      resource = Resource.last
      expect(resource.tweet).to eq(Tweet.last)
      expect(resource.title).to eq('12ft - Hop any paywall')
      expect(resource.url).to eq('https://12ft.io/')
    end
  end
end
