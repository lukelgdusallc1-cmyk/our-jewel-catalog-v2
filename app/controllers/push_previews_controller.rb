class PushPreviewsController < ApplicationController
  MAX_PRODUCTS = 50

  def show
    @selected_skus = normalize_skus(params[:skus])

    @products = SupplierProduct
      .where(stock_no: @selected_skus)
      .order(:stock_no)
      .limit(MAX_PRODUCTS)
      .to_a

    builder = Sync::PushPreviewBuilder.new(
      settings: CatalogSetting.current
    )

    @previews = @products.map do |product|
      {
        product: product,
        preview: builder.build(product)
      }
    end

    @preview_token = verifier.generate(
      {
        "skus" => @products.map(&:stock_no),
        "shop" => shop_identity
      },
      expires_in: 30.minutes,
      purpose: :shopify_push_preview
    )
  end

  def publish
    payload = verifier.verified(
      params[:preview_token],
      purpose: :shopify_push_preview
    )

    unless payload.is_a?(Hash) &&
           payload["shop"] == shop_identity
      redirect_to root_path,
        alert: "Preview expired or invalid. Preview the products again."
      return
    end

    approved_skus = Array(payload["skus"])
    requested_skus = normalize_skus(params[:skus])

    if requested_skus.empty? ||
       (requested_skus - approved_skus).any?
      redirect_to root_path,
        alert: "No valid approved products selected."
      return
    end

    if requested_skus.size > MAX_PRODUCTS
      redirect_to root_path,
        alert: "Maximum #{MAX_PRODUCTS} products per push."
      return
    end

    shopify_session = ShopifyAPI::Context.active_session

    unless shopify_session
      redirect_to root_path,
        alert: "Shopify session missing. Reconnect the app."
      return
    end

    publisher = Shopify::ProductPublisher.new(
      session: shopify_session,
      settings: CatalogSetting.current
    )

    @results = []

    requested_skus.each do |sku|
      product = SupplierProduct.find_by(stock_no: sku)

      unless product
        @results << {
          sku: sku,
          status: "failed",
          message: "Supplier product no longer exists"
        }
        next
      end

      begin
        result = publisher.publish!(product)

        @results << result

      rescue StandardError => e
        Rails.logger.error(
          "Push failed for #{sku}: #{e.class}: #{e.message}"
        )

        @results << {
          sku: sku,
          status: "failed",
          message: e.message
        }
      end
    end

    @created = @results.count do |result|
      result[:status] == "created"
    end

    @skipped = @results.count do |result|
      result[:status] == "skipped"
    end

    @failed = @results.count do |result|
      result[:status] == "failed"
    end

    SyncEvent.create!(
      event_type: "shopify_push",
      status: @failed.zero? ? "success" : "failed",
      message: "Created: #{@created}, " \
               "Skipped: #{@skipped}, Failed: #{@failed}"
    )

    render :result
  end

  private

  def normalize_skus(values)
    Array(values)
      .flat_map { |value| value.to_s.split(",") }
      .map(&:strip)
      .reject(&:blank?)
      .uniq
      .first(251)
  end

  def verifier
    Rails.application.message_verifier(:supplier_push)
  end

  def shop_identity
    return "local-development" unless Rails.env.production?

    current_shopify_session&.shop ||
      ShopifyAPI::Context.active_session&.shop
  end
end