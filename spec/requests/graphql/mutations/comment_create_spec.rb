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
end
