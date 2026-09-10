require "nokogiri"
require "open-uri"

class OpenGraphExtractor
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5

  def self.call(url, **options)
    new(**options).call(url)
  end

  def initialize(url_safety: UrlSafety.new, logger: Rails.logger,
                 open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT)
    @url_safety = url_safety
    @logger = logger
    @open_timeout = open_timeout
    @read_timeout = read_timeout
  end

  def call(url)
    return nil unless @url_safety.safe?(url)

    html = fetch(url)
    return nil if html.nil?

    extract(Nokogiri::HTML(html), url)
  end

  private

  def fetch(url)
    URI.open(url, open_timeout: @open_timeout, read_timeout: @read_timeout, &:read)
  rescue StandardError => e
    @logger.error "Failed to fetch OpenGraph for #{url}: #{e.message}"
    nil
  end

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
