require 'rails_helper'

RSpec.describe UrlExtractor do
  describe '.call' do
    it 'extracts a single URL from the text' do
      text = 'Best thing I found in a while: https://12ft.io/'
      urls = UrlExtractor.call(text)
      
      expect(urls).to eq(['https://12ft.io/'])
    end

    it 'extracts multiple URLs from the text' do
      text = 'Check https://google.com and also http://example.org/test'
      urls = UrlExtractor.call(text)
      
      expect(urls).to eq(['https://google.com', 'http://example.org/test'])
    end

    it 'returns an empty array if no URLs are present' do
      text = 'Just a normal tweet without any links.'
      urls = UrlExtractor.call(text)
      
      expect(urls).to eq([])
    end

    it 'ignores invalid URLs without http/https' do
      text = 'Go to www.google.com'
      urls = UrlExtractor.call(text)
      
      expect(urls).to eq([]) 
    end
  end
end