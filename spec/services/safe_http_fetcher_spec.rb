require 'rails_helper'

RSpec.describe SafeHttpFetcher do
  subject(:fetcher) do
    described_class.new(url_safety: url_safety, max_redirects: 2, max_bytes: 2_000_000)
  end

  let(:url_safety) { instance_double(UrlSafety) }
  let(:body) { '<html><head></head></html>' }

  def redirect_to(location)
    OpenURI::HTTPRedirect.new('302 Found', nil, URI(location))
  end

  describe '#fetch' do
    it 'returns the body for a safe url' do
      allow(url_safety).to receive(:safe?).with('https://public.example/').and_return(true)
      allow(URI).to receive(:open) { |*_a, **_o, &block| block.call(StringIO.new(body)) }

      expect(fetcher.fetch('https://public.example/')).to eq(body)
    end

    it 'never opens and returns nil for an unsafe url' do
      allow(url_safety).to receive(:safe?).with('http://169.254.169.254/').and_return(false)
      allow(URI).to receive(:open)

      expect(fetcher.fetch('http://169.254.169.254/')).to be_nil
      expect(URI).not_to have_received(:open)
    end

    it 'passes open/read timeouts and disables automatic redirects' do
      allow(url_safety).to receive(:safe?).and_return(true)
      allow(URI).to receive(:open) { |*_a, **_o, &block| block.call(StringIO.new(body)) }

      fetcher.fetch('https://public.example/')

      expect(URI).to have_received(:open)
        .with('https://public.example/', hash_including(open_timeout: 5, read_timeout: 5, redirect: false))
    end

    it 'follows a redirect only after re-checking the destination is safe' do
      allow(url_safety).to receive(:safe?).with('https://public.example/').and_return(true)
      allow(url_safety).to receive(:safe?).with('https://public.example/final').and_return(true)

      call = 0
      allow(URI).to receive(:open) do |_url, **_opts, &block|
        call += 1
        raise redirect_to('https://public.example/final') if call == 1

        block.call(StringIO.new(body))
      end

      expect(fetcher.fetch('https://public.example/')).to eq(body)
    end

    it 'does not follow a redirect to an unsafe address' do
      allow(url_safety).to receive(:safe?).with('https://public.example/').and_return(true)
      allow(url_safety).to receive(:safe?).with('http://169.254.169.254/').and_return(false)
      allow(URI).to receive(:open).and_raise(redirect_to('http://169.254.169.254/'))

      expect(fetcher.fetch('https://public.example/')).to be_nil
    end

    it 'gives up after too many redirects' do
      allow(url_safety).to receive(:safe?).and_return(true)
      allow(URI).to receive(:open).and_raise(redirect_to('https://public.example/loop'))

      expect(fetcher.fetch('https://public.example/')).to be_nil
    end

    it 'rejects a response larger than the byte limit' do
      allow(url_safety).to receive(:safe?).and_return(true)
      allow(URI).to receive(:open) { |_url, **opts, &_block| opts[:content_length_proc].call(9_999_999) }

      expect(fetcher.fetch('https://public.example/')).to be_nil
    end

    it 'returns nil when the network fails' do
      allow(url_safety).to receive(:safe?).and_return(true)
      allow(URI).to receive(:open).and_raise(StandardError, 'Net::ReadTimeout')

      expect(fetcher.fetch('https://public.example/')).to be_nil
    end
  end
end
