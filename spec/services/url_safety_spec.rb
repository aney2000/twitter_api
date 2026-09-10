require 'rails_helper'

RSpec.describe UrlSafety do
  subject(:url_safety) { described_class.new(resolver: resolver) }

  let(:resolver) { class_double(Resolv) }

  describe '#safe?' do
    it 'is true for a public host that resolves to a public ip' do
      allow(resolver).to receive(:getaddresses).with('example.com').and_return([ '93.184.216.34' ])

      expect(url_safety.safe?('https://example.com/page')).to be(true)
    end

    it 'is false for a host that resolves to a private ip' do
      allow(resolver).to receive(:getaddresses).with('intranet').and_return([ '10.0.0.5' ])

      expect(url_safety.safe?('http://intranet/')).to be(false)
    end

    it 'blocks the cloud metadata ip literal without resolving' do
      expect(url_safety.safe?('http://169.254.169.254/latest/meta-data/')).to be(false)
    end

    it 'blocks loopback ip literals' do
      expect(url_safety.safe?('http://127.0.0.1:8080/')).to be(false)
    end

    it 'blocks private ip literals' do
      expect(url_safety.safe?('http://192.168.1.10/')).to be(false)
    end

    it 'allows a public ip literal' do
      expect(url_safety.safe?('https://93.184.216.34/')).to be(true)
    end

    it 'is false for non-http schemes' do
      expect(url_safety.safe?('file:///etc/passwd')).to be(false)
      expect(url_safety.safe?('ftp://example.com/')).to be(false)
    end

    it 'is false for a malformed url' do
      expect(url_safety.safe?('http://')).to be(false)
    end
  end
end
