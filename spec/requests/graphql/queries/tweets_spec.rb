require 'rails_helper'

RSpec.describe 'GraphQL Queries: tweets', type: :request do
  describe 'querying a list of tweets' do
    let!(:tweet1) { Tweet.create!(content: 'Check this out: https://example.com') }
    let!(:tweet2) { Tweet.create!(content: 'Another tweet here.') }

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

    it 'returns all tweets with their mapped fields' do
      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['tweets']

      expect(response).to have_http_status(:ok)
      expect(data.length).to eq(2)
      
      expect(data.first['message']).to eq('Check this out: https://example.com')
      expect(data.first['uuid']).to eq(tweet1.uuid)
      
      expect(data.first['resources']).to be_an(Array)
    end
  end
end