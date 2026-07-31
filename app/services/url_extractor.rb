require "uri"

class UrlExtractor
  def self.call(text)
    return [] if text.blank?

    URI.extract(text, [ "http", "https" ]).uniq
  end
end
