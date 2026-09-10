class ResourceExtractor
  def self.call(record, **options)
    new(**options).call(record)
  end

  def initialize(url_extractor: UrlExtractor, og_extractor: OpenGraphExtractor)
    @url_extractor = url_extractor
    @og_extractor = og_extractor
  end

  def call(record)
    @url_extractor.call(record.content).each do |url|
      metadata = @og_extractor.call(url)
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
