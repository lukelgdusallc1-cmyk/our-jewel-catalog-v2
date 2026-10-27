module ProductContent
  class PhotoBuilder
    def initialize(settings:)
      @settings = settings
    end

    def call(product)
      pattern = @settings.photo_url_pattern.presence ||
                "https://dna3.dnalinks.in/{stockNo}/{n}.jpg"

      urls = []

      if pattern.include?("{stockNo}") && pattern.include?("{n}")
        count = @settings.photos_per_product.to_i
        count = 4 if count <= 0

        (1..count).each do |n|
          url = pattern
                  .gsub("{stockNo}", product.stock_no.to_s)
                  .gsub("{n}", n.to_s)

          urls << url if url.start_with?("https://")
        end
      end

      if urls.empty? && product.photo_url.to_s.start_with?("https://")
        urls << product.photo_url
      end

      urls.uniq
    end
  end
end