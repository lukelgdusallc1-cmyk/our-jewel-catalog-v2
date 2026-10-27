class CatalogController < ApplicationController
  def index
    @categories = SupplierProduct.distinct.order(:category)
                                 .pluck(:category)
                                 .compact
                                 .reject(&:blank?)

    @products = SupplierProduct.order(:stock_no)
    @products = @products.where(category: params[:category]) if params[:category].present?

    if params[:q].present?
      text = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @products = @products.where(
        "stock_no ILIKE ? OR title ILIKE ? OR remarks ILIKE ?",
        text, text, text
      )
    end

    @count = @products.count
    @products = @products.limit(250)

    @shopify_skus = nil

    if Rails.env.production?
      begin
        @shopify_skus = Shopify::SkuReader.call(
          session: current_shopify_session
        )
      rescue StandardError => e
        Rails.logger.error(
          "Shopify SKU lookup failed: #{e.class}: #{e.message}"
        )
      end
    end

    @sample_skus = CatalogSetting.current.sample_sku_set if Rails.env.development?
  end

  def show
    @product = SupplierProduct.find(params[:id])
    @preview = Sync::PushPreviewBuilder.new(
      settings: CatalogSetting.current
    ).build(@product)
  end
end