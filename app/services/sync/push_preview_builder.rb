module Sync
  class PushPreviewBuilder
    def initialize(settings:)
      @settings = settings
    end
    def build(product)
      { stock_no: product.stock_no,
        title: ProductContent::TitleBuilder.new(settings: @settings).call(product),
        vendor: @settings.vendor_name,
        price: Pricing::PriceCalculator.new(settings: @settings).call(product),
        inventory: product.inhand_pcs,
        photos: ProductContent::PhotoBuilder.new(settings: @settings).call(product),
        inventory_location_label: @settings.inventory_location_label,
        demo: product.demo }
    end
  end
end
