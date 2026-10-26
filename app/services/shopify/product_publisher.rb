module Shopify
  class ProductPublisher
    def publish!(_product)
      raise NotImplementedError, 'Shopify product publishing is intentionally disabled pending approval and write scopes.'
    end
  end
end
