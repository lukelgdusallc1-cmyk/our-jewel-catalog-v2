module Shopify
  class ProductReader
    def variant_skus
      raise NotImplementedError, 'Connect real Shopify Admin API after HTTPS deployment and merchant authorization.'
    end
  end
end
