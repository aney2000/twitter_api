require "nokogiri"

class OpenGraphExtractor
  def self.call(url, **options)
    new(**options).call(url)
  end

  def initialize(fetcher: SafeHttpFetcher.new)
    @fetcher = fetcher
  end

  def call(url)
    html = @fetcher.fetch(url)
    return nil if html.nil?

    extract(Nokogiri::HTML(html), url)
  end

  private

  def extract(doc, url)
    {
      title: meta(doc, "og:title") || meta(doc, "twitter:title"),
      description: meta(doc, "og:description") || meta(doc, "twitter:description"),
      url: meta(doc, "og:url") || url,
      image_url: meta(doc, "og:image") || meta(doc, "twitter:image")
    }
  end

  def meta(doc, property)
    node = doc.at_css("meta[property='#{property}']")
    node ? node["content"] : nil
  end
end
