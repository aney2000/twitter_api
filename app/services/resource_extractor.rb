class ResourceExtractor
  def self.call(record)
    UrlExtractor.call(record.content).each do |url|
      metadata = OpenGraphExtractor.call(url)
      next unless metadata

      record.resources.create!(
        title: metadata[:title],
        description: metadata[:description],
        url: metadata[:url],
        image_url: metadata[:image_url]
      )
    end
  end
end
