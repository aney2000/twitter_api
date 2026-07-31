require 'rails_helper'

RSpec.describe OpenGraphExtractor do
  describe '.call' do
    let(:url) { 'https://12ft.io/' }

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

    before do
      allow_any_instance_of(URI::HTTP).to receive(:read).and_return(html_body)
      allow_any_instance_of(URI::HTTPS).to receive(:read).and_return(html_body)
      allow(URI).to receive(:open).with(url).and_return(StringIO.new(html_body))
    end

    it 'extracts the Open Graph metadata correctly' do
      result = OpenGraphExtractor.call(url)

      expect(result[:title]).to eq('12ft - Hop any paywall')
      expect(result[:description]).to eq("Show me a 10ft paywall, I'll show you a 12ft ladder")
      expect(result[:url]).to eq('https://12ft.io/')
      expect(result[:image_url]).to eq('https://12ft.io/og-banner.png')
    end

    it 'returns nil if the url is invalid or fetching fails' do
      allow(URI).to receive(:open).and_raise(StandardError, "Net::ReadTimeout")

      result = OpenGraphExtractor.call('https://bad-site.com')
      expect(result).to be_nil
    end
  end
end
