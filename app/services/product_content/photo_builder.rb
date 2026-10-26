module ProductContent
  class PhotoBuilder
    def initialize(settings:)
      @settings = settings
    end
    def call(product)
      pattern = @settings.photo_url_pattern.to_s
      urls = []
      if pattern.present? && pattern.include?('{stockNo}') && pattern.include?('{n}')
        (1..@settings.photos_per_product).each do |n|
          url = pattern.gsub('{stockNo}', product.stock_no.to_s).gsub('{n}', n.to_s)
          urls << url if url.start_with?('https://')
        end
      end
      urls << product.photo_url if urls.empty? && product.photo_url.to_s.start_with?('https://')
      urls.uniq
    end
  end
end
