
class PushPreviewsController < ApplicationController
  def show
    @selected_skus = Array(params[:skus])
      .flat_map { |value| value.to_s.split(",") }
      .map(&:strip)
      .reject(&:blank?)
      .uniq
      .first(250)

    products = SupplierProduct.order(:stock_no)

    if @selected_skus.any?
      products = products.where(stock_no: @selected_skus)
    end

    @products = products.limit(250).to_a

    builder = Sync::PushPreviewBuilder.new(
      settings: CatalogSetting.current
    )

    @previews = @products.map do |product|
      {
        product: product,
        preview: builder.build(product)
      }
    end
  end
end
