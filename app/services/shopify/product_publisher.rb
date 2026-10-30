module Shopify
  class ProductPublisher
    class PublishError < StandardError; end

    def initialize(session:, settings: CatalogSetting.current)
      raise PublishError, "Shopify session missing" if session.nil?

      @client = ShopifyAPI::Clients::Graphql::Admin.new(
        session: session
      )
      @settings = settings
      @builder = Sync::PushPreviewBuilder.new(
        settings: settings
      )
    end

    def publish!(supplier_product)
      preview = @builder.build(supplier_product)

      sku = preview[:stock_no].to_s.strip
      title = preview[:title].to_s.strip
      price = preview[:price]

      raise PublishError, "SKU is missing" if sku.blank?
      raise PublishError, "Title is missing for #{sku}" if title.blank?
      raise PublishError, "Price is missing for #{sku}" if price.nil?
      raise PublishError, "Invalid price for #{sku}" if price.to_d < 0

      if sku_exists?(sku)
        return {
          status: "skipped",
          sku: sku,
          message: "SKU already exists in Shopify"
        }
      end

      product_id = nil

      begin
        product = create_product(preview, supplier_product)
        product_id = product.fetch("id")

        variant = product.fetch("variants")
                         .fetch("nodes")
                         .first

        raise PublishError, "Default variant missing" unless variant

        updated_variant = update_variant(
          product_id: product_id,
          variant_id: variant.fetch("id"),
          preview: preview
        )

        inventory_item = updated_variant.fetch("inventoryItem")

        unless inventory_item["tracked"]
          raise PublishError, "Inventory tracking was not enabled"
        end

        inventory_item_id = inventory_item.fetch("id")
        quantity = preview[:inventory].to_i

        raise PublishError, "Invalid inventory quantity" if quantity.negative?

        set_inventory(
          inventory_item_id: inventory_item_id,
          quantity: quantity
        )

        activate_product(product_id)

        {
          status: "created",
          sku: sku,
          product_id: product_id,
          message: "Product created successfully"
        }

      rescue StandardError => e
        Rails.logger.error(
          "Shopify publish failed for #{sku}: " \
          "#{e.class}: #{e.message}"
        )

        # An incomplete product stays in Draft status.
        # Do not automatically retry without checking Shopify.
        raise PublishError,
              "#{e.message}" +
              (product_id ? " (Draft product ID: #{product_id})" : "")
      end
    end

    private

    def graphql(query, variables = {})
      response = @client.query(
        query: query,
        variables: variables
      )

      body = response.body

      if body["errors"].present?
        messages = body["errors"].map do |error|
          error["message"]
        end

        raise PublishError, messages.join("; ")
      end

      body.fetch("data")
    end

    def mutation_result(data, key)
      result = data.fetch(key)

      errors = result["userErrors"] || []

      if errors.any?
        message = errors.map do |error|
          error["message"]
        end.join("; ")

        raise PublishError, message
      end

      result
    end

    def sku_exists?(sku)
      query = <<~GRAPHQL
        query($search: String!) {
          productVariants(first: 10, query: $search) {
            nodes {
              id
              sku
            }
          }
        }
      GRAPHQL

      # Quote and escape the SKU for Shopify search syntax.
      escaped_sku = sku.gsub("\\", "\\\\\\")
                       .gsub('"', '\\"')

      data = graphql(
        query,
        { search: "sku:\"#{escaped_sku}\"" }
      )

      data.fetch("productVariants")
          .fetch("nodes")
          .any? do |variant|
        variant["sku"].to_s.strip.casecmp?(sku)
      end
    end

    def create_product(preview, supplier_product)
      mutation = <<~GRAPHQL
        mutation($product: ProductCreateInput!, $media: [CreateMediaInput!]) {
          productCreate(product: $product, media: $media) {
            product {
              id
              status
              variants(first: 1) {
                nodes {
                  id
                  inventoryItem {
                    id
                  }
                }
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL

      description = supplier_product.remarks.presence ||
                    preview[:title]

      product_input = {
        title: preview[:title],
        vendor: preview[:vendor],
        descriptionHtml: ERB::Util.html_escape(description),
        status: "DRAFT"
      }

      if supplier_product.category.present?
        product_input[:productType] = supplier_product.category
      end

      photos = Array(preview[:photos])
        .select { |url| url.to_s.start_with?("https://") }
        .uniq
        .first(10)

      media = photos.map do |url|
        {
          originalSource: url,
          mediaContentType: "IMAGE",
          alt: preview[:title]
        }
      end

      data = graphql(
        mutation,
        {
          product: product_input,
          media: media
        }
      )

      result = mutation_result(data, "productCreate")
      product = result["product"]

      raise PublishError, "Shopify did not return a product" unless product

      product
    end

    def update_variant(product_id:, variant_id:, preview:)
      mutation = <<~GRAPHQL
        mutation(
          $productId: ID!,
          $variants: [ProductVariantsBulkInput!]!
        ) {
          productVariantsBulkUpdate(
            productId: $productId,
            variants: $variants
          ) {
            productVariants {
              id
              price
              inventoryItem {
                id
                sku
                tracked
              }
            }
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL

      variants = [
        {
          id: variant_id,
          price: preview[:price].to_d.to_s("F"),
          inventoryItem: {
            sku: preview[:stock_no].to_s,
            tracked: true
          }
        }
      ]

      data = graphql(
        mutation,
        {
          productId: product_id,
          variants: variants
        }
      )

      result = mutation_result(
        data,
        "productVariantsBulkUpdate"
      )

      updated_variant = result.fetch("productVariants").first

      unless updated_variant
        raise PublishError, "Shopify variant update returned no variant"
      end

      updated_variant
    end

    def refresh_inventory_item(product_id:)
      query = <<~GRAPHQL
        query($id: ID!) {
          product(id: $id) {
            variants(first: 1) {
              nodes {
                inventoryItem {
                  id
                }
              }
            }
          }
        }
      GRAPHQL

      data = graphql(query, { id: product_id })

      data.fetch("product")
          .fetch("variants")
          .fetch("nodes")
          .first
          .fetch("inventoryItem")
          .fetch("id")
    end

    def location_id
      return @location_id if defined?(@location_id)

      query = <<~GRAPHQL
        query {
          locations(first: 100) {
            nodes {
              id
              name
              isActive
              fulfillsOnlineOrders
            }
          }
        }
      GRAPHQL

      data = graphql(query)

      locations = data.fetch("locations").fetch("nodes")

      requested_name = @settings.inventory_location_label.to_s.strip

      location =
        if requested_name.present?
          locations.find do |item|
            item["name"].to_s.casecmp?(requested_name) &&
              item["isActive"]
          end
        else
          locations.find do |item|
            item["isActive"] && item["fulfillsOnlineOrders"]
          end || locations.find { |item| item["isActive"] }
        end

      unless location
        raise PublishError,
              "No matching active Shopify inventory location found"
      end

      @location_id = location.fetch("id")
    end

    def set_inventory(inventory_item_id:, quantity:)
      location = location_id

      activate_mutation = <<~GRAPHQL
        mutation($inventoryItemId: ID!, $locationId: ID!) {
          inventoryActivate(
            inventoryItemId: $inventoryItemId,
            locationId: $locationId
          ) {
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL

      activation = graphql(
        activate_mutation,
        {
          inventoryItemId: inventory_item_id,
          locationId: location
        }
      )

      mutation_result(activation, "inventoryActivate")

      quantity_mutation = <<~GRAPHQL
        mutation($input: InventorySetQuantitiesInput!) {
          inventorySetQuantities(input: $input) {
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL

      input = {
        name: "available",
        reason: "correction",
        ignoreCompareQuantity: true,
        quantities: [
          {
            inventoryItemId: inventory_item_id,
            locationId: location,
            quantity: quantity
          }
        ]
      }

      data = graphql(
        quantity_mutation,
        { input: input }
      )

      mutation_result(data, "inventorySetQuantities")
    end

    def activate_product(product_id)
      mutation = <<~GRAPHQL
        mutation($product: ProductUpdateInput!) {
          productUpdate(product: $product) {
            product {
              id
              status
            }
            userErrors {
              field
              message
            }
          }
        }
      GRAPHQL

      data = graphql(
        mutation,
        {
          product: {
            id: product_id,
            status: "ACTIVE"
          }
        }
      )

      mutation_result(data, "productUpdate")
    end
  end
end