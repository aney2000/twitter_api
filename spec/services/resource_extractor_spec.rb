require 'rails_helper'

RSpec.describe ResourceExtractor do
  describe '.call' do
    let(:tweet) { Tweet.create!(content: 'Best thing I found in a while: https://12ft.io/') }

    before do
      allow(OpenGraphExtractor).to receive(:call).with('https://12ft.io/').and_return({
        title: '12ft - Hop any paywall',
        description: 'Show me a 10ft paywall',
        url: 'https://12ft.io/',
        image_url: 'https://12ft.io/og-banner.png'
      })
    end

    it 'saves a resource for each url found in the record content' do
      expect { ResourceExtractor.call(tweet) }.to change(Resource, :count).by(1)

      resource = tweet.resources.last
      expect(resource.title).to eq('12ft - Hop any paywall')
      expect(resource.description).to eq('Show me a 10ft paywall')
      expect(resource.url).to eq('https://12ft.io/')
      expect(resource.image_url).to eq('https://12ft.io/og-banner.png')
    end

    it 'saves nothing when the content has no urls' do
      plain_tweet = Tweet.create!(content: 'Just a thought, no links today')

      expect { ResourceExtractor.call(plain_tweet) }.not_to change(Resource, :count)
    end

    it 'skips urls whose open graph metadata could not be fetched' do
      allow(OpenGraphExtractor).to receive(:call).with('https://12ft.io/').and_return(nil)

      expect { ResourceExtractor.call(tweet) }.not_to change(Resource, :count)
    end

    it 'uses the injected url and open graph extractors' do
      url_extractor = class_double(UrlExtractor, call: [ 'https://12ft.io/' ])
      og_extractor = class_double(
        OpenGraphExtractor,
        call: { title: 'T', description: 'D', url: 'https://12ft.io/', image_url: 'https://12ft.io/i.png' }
      )

      extractor = described_class.new(url_extractor: url_extractor, og_extractor: og_extractor)

      expect { extractor.call(tweet) }.to change(Resource, :count).by(1)
      expect(url_extractor).to have_received(:call).with(tweet.content)
      expect(og_extractor).to have_received(:call).with('https://12ft.io/')
    end
  end
end
