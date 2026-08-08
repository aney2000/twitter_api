require 'rails_helper'

RSpec.describe 'GraphQL Mutations: commentCreate', type: :request do
  let!(:tweet) { Tweet.create!(content: 'Best thing I found in a while: https://12ft.io/') }

  let(:mutation) do
    <<~GQL
      mutation($input: CommentCreateInput!) {
        commentCreate(input: $input) {
          comment {
            uuid
          }
        }
      }
    GQL
  end

  let(:variables) do
    {
      input: {
        tweetUuid: tweet.uuid,
        content: 'Nice find, thanks for sharing'
      }
    }
  end

  it 'creates a comment on the given tweet and returns its uuid' do
    expect {
      post '/graphql', params: { query: mutation, variables: variables }
    }.to change(Comment, :count).by(1)

    json = JSON.parse(response.body)
    data = json.dig('data', 'commentCreate', 'comment')

    expect(response).to have_http_status(:ok)

    comment = Comment.last
    expect(data['uuid']).to eq(comment.uuid)
    expect(comment.tweet).to eq(tweet)
    expect(comment.content).to eq('Nice find, thanks for sharing')
  end

  context 'when the comment content contains a url' do
    let(:variables) do
      {
        input: {
          tweetUuid: tweet.uuid,
          content: 'This is exactly the ladder I needed: https://12ft.io/'
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

    it 'saves the open graph metadata against the comment' do
      expect {
        post '/graphql', params: { query: mutation, variables: variables }
      }.to change(Resource, :count).by(1)

      comment = Comment.last
      resource = Resource.last

      expect(resource.resourceable).to eq(comment)
      expect(resource.title).to eq('12ft - Hop any paywall')
      expect(resource.url).to eq('https://12ft.io/')
      expect(resource.image_url).to eq('https://12ft.io/og-banner.png')
    end
  end
end
