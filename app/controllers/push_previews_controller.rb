class PushPreviewsController < ApplicationController
  def show
    @products = SupplierProduct.order(:stock_no).limit(50)
    builder = Sync::PushPreviewBuilder.new(settings: CatalogSetting.current)
    @previews = @products.map { |p| builder.build(p) }
  end
end
