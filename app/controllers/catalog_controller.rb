class CatalogController < ApplicationController
  def index
    @categories = SupplierProduct.distinct.order(:category).pluck(:category).compact.reject(&:blank?)
    @products = SupplierProduct.order(:stock_no)
    @products = @products.where(category: params[:category]) if params[:category].present?
    if params[:q].present?
      text = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @products = @products.where('stock_no ILIKE ? OR title ILIKE ? OR remarks ILIKE ?', text, text, text)
    end
    @count = @products.count
    @products = @products.limit(250)
    @sample_skus = CatalogSetting.current.sample_sku_set
  end
  def show
    @product = SupplierProduct.find(params[:id])
    @preview = Sync::PushPreviewBuilder.new(settings: CatalogSetting.current).build(@product)
  end
end
