module Pricing
  class PriceCalculator
    def initialize(settings:)
      @settings = settings
    end
    def call(product)
      return nil if product.supplier_price.nil?
      markup = @settings.markup_for(product.category)
      (product.supplier_price * (1 + markup / 100)).round(2)
    end
  end
end
