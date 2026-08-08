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
  end
end
