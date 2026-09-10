require 'rails_helper'

RSpec.describe OpenGraphExtractor do
  let(:url) { 'https://12ft.io/' }
  let(:url_safety) { instance_double(UrlSafety, safe?: true) }

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

  subject(:extractor) { described_class.new(url_safety: url_safety) }

  describe '#call' do
    context 'for a safe url' do
      before do
        allow(URI).to receive(:open) { |*_args, **_opts, &block| block.call(StringIO.new(html_body)) }
      end

      it 'extracts the Open Graph metadata correctly' do
        result = extractor.call(url)

        expect(result[:title]).to eq('12ft - Hop any paywall')
        expect(result[:description]).to eq("Show me a 10ft paywall, I'll show you a 12ft ladder")
        expect(result[:url]).to eq('https://12ft.io/')
        expect(result[:image_url]).to eq('https://12ft.io/og-banner.png')
      end

      it 'fetches with open and read timeouts' do
        extractor.call(url)

        expect(URI).to have_received(:open).with(url, hash_including(open_timeout: 5, read_timeout: 5))
      end

      it 'returns nil when fetching fails' do
        allow(URI).to receive(:open).and_raise(StandardError, 'Net::ReadTimeout')

        expect(extractor.call(url)).to be_nil
      end
    end

    context 'for an unsafe url' do
      let(:url_safety) { instance_double(UrlSafety, safe?: false) }

      it 'never fetches and returns nil' do
        allow(URI).to receive(:open)

        expect(extractor.call('http://169.254.169.254/')).to be_nil
        expect(URI).not_to have_received(:open)
      end
    end
  end
end
