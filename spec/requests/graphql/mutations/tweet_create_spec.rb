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

    it 'creates a new tweet and returns its uuid' do
      expect {
        post '/graphql', params: { query: mutation, variables: variables }
      }.to change(Tweet, :count).by(1)

      json = JSON.parse(response.body)
      data = json.dig('data', 'tweetCreate', 'tweet')

      expect(response).to have_http_status(:ok)
      expect(data['uuid']).to be_present
      
      expect(data['uuid']).to eq(Tweet.last.uuid)
    end
  end
end