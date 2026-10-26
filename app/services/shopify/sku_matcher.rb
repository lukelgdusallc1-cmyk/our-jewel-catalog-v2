require 'set'
module Shopify
  class SkuMatcher
    def initialize(skus:)
      @skus = skus.map { |sku| sku.to_s.strip.upcase }.to_set
    end
    def in_store?(product)
      @skus.include?(product.stock_no.to_s.strip.upcase)
    end
  end
end
