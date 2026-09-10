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

  describe 'querying tweets with their comments' do
    let!(:tweet) { Tweet.create!(content: 'Best thing I found in a while: https://12ft.io/') }

    let!(:comment) do
      tweet.comments.create!(content: 'This is exactly the ladder I needed: https://12ft.io/')
    end

    let!(:comment_resource) do
      comment.resources.create!(
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
            comments {
              uuid
              message
              resources {
                title
                description
                url
                image {
                  url
                }
              }
            }
          }
        }
      GQL
    end

    it 'returns each tweet with its comments and their resources' do
      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['tweets']

      expect(response).to have_http_status(:ok)

      first_comment = data.first['comments'].first
      expect(first_comment['uuid']).to eq(comment.uuid)
      expect(first_comment['message']).to eq('This is exactly the ladder I needed: https://12ft.io/')

      first_resource = first_comment['resources'].first
      expect(first_resource['title']).to eq('12ft - Hop any paywall')
      expect(first_resource['description']).to eq('Show me a 10ft paywall')
      expect(first_resource['url']).to eq('https://12ft.io/')
      expect(first_resource['image']['url']).to eq('https://12ft.io/og-banner.png')
    end
  end

  describe 'query efficiency' do
    let(:query) do
      <<~GQL
        query {
          tweets {
            uuid
            message
            resources {
              title
              url
            }
            comments {
              uuid
              message
              resources {
                title
                url
              }
            }
          }
        }
      GQL
    end

    def seed(tweets:, comments_each:)
      tweets.times do
        tweet = Tweet.create!(content: 'A tweet: https://12ft.io/')
        tweet.resources.create!(url: 'https://12ft.io/')

        comments_each.times do
          comment = tweet.comments.create!(content: 'A comment: https://12ft.io/')
          comment.resources.create!(url: 'https://12ft.io/')
        end
      end
    end

    it 'fires the same number of queries however many tweets and comments exist' do
      seed(tweets: 1, comments_each: 1)
      small = count_queries { post '/graphql', params: { query: query } }

      seed(tweets: 2, comments_each: 3)
      large = count_queries { post '/graphql', params: { query: query } }

      expect(large).to eq(small)
    end
  end
end
