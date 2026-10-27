
require "set"

module Shopify
  class SkuReader
    CACHE_DURATION = 5.minutes

    QUERY = <<~GRAPHQL
      query($cursor: String) {
        productVariants(first: 250, after: $cursor) {
          nodes {
            sku
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    GRAPHQL

    def self.call(session:)
      raise ArgumentError, "Shopify session missing" if session.nil?

      cache_key = "shopify/variant_skus/#{session.shop}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
        fetch_skus(session: session).to_a
      end.to_set
    end

    def self.fetch_skus(session:)
      client = ShopifyAPI::Clients::Graphql::Admin.new(
        session: session
      )

      skus = Set.new
      cursor = nil

      loop do
        response = client.query(
          query: QUERY,
          variables: { cursor: cursor }
        )

        body = response.body
        raise "Shopify GraphQL errors" if body["errors"].present?

        variants = body.fetch("data").fetch("productVariants")

        variants.fetch("nodes").each do |variant|
          sku = variant["sku"].to_s.strip.upcase
          skus.add(sku) unless sku.empty?
        end

        page_info = variants.fetch("pageInfo")
        break unless page_info["hasNextPage"]

        cursor = page_info.fetch("endCursor")
      end

      skus
    end

    private_class_method :fetch_skus
  end
end
