module Mutations
  class TweetCreate < BaseMutation
    description "Creates a new tweet"

    argument :content, String, required: true

    field :tweet, Types::TweetType, null: true
    field :errors, [String], null: false

    def resolve(content:)
      tweet = Tweet.new(content: content)

      if tweet.save
        # --------------------------------------------------------
        urls = UrlExtractor.call(content)
        
        urls.each do |url|
          metadata = OpenGraphExtractor.call(url)
          
          if metadata
            tweet.resources.create!(
              title: metadata[:title],
              description: metadata[:description],
              url: metadata[:url],
              image_url: metadata[:image_url]
            )
          end
        end
        # --------------------------------------------------------

        {
          tweet: tweet,
          errors: []
        }
      else
        {
          tweet: nil,
          errors: tweet.errors.full_messages
        }
      end
    end
  end
end