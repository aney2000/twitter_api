require 'rails_helper'

RSpec.describe OpenGraphExtractor do
  let(:url) { 'https://12ft.io/' }
  let(:fetcher) { instance_double(SafeHttpFetcher) }

  let(:html_body) do
    <<~HTML
      <html>
        <head>
          <meta property="og:title" content="12ft - Hop any paywall">
          <meta property="og:description" content="Show me a 10ft paywall, I'll show you a 12ft ladder">
          <meta property="og:url" content="https://12ft.io/">
          <meta property="og:image" content="https://12ft.io/og-banner.png">
        </head>
      </html>
    HTML
  end

  subject(:extractor) { described_class.new(fetcher: fetcher) }

  describe '#call' do
    it 'extracts the Open Graph metadata from the fetched html' do
      allow(fetcher).to receive(:fetch).with(url).and_return(html_body)

      result = extractor.call(url)

      expect(result[:title]).to eq('12ft - Hop any paywall')
      expect(result[:description]).to eq("Show me a 10ft paywall, I'll show you a 12ft ladder")
      expect(result[:url]).to eq('https://12ft.io/')
      expect(result[:image_url]).to eq('https://12ft.io/og-banner.png')
    end

    it 'returns nil when the fetch yields nothing' do
      allow(fetcher).to receive(:fetch).and_return(nil)

      expect(extractor.call(url)).to be_nil
    end
  end
end
