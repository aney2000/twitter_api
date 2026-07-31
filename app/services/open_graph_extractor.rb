require "nokogiri"
require "open-uri"

class OpenGraphExtractor
  def self.call(url)
    begin
      html = URI.open(url).read
    rescue StandardError => e
      Rails.logger.error "Failed to fetch OpenGraph for #{url}: #{e.message}"
      return nil
    end

    doc = Nokogiri::HTML(html)

    extract_content = ->(property) {
      node = doc.at_css("meta[property='#{property}']")
      node ? node["content"] : nil
    }

    {
      title: extract_content.call("og:title") || extract_content.call("twitter:title"),
      description: extract_content.call("og:description") || extract_content.call("twitter:description"),
      url: extract_content.call("og:url") || url,
      image_url: extract_content.call("og:image") || extract_content.call("twitter:image")
    }
  end
end
