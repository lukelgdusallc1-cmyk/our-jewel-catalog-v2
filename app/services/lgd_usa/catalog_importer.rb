
module LgdUsa
  class CatalogImporter
    class CooldownError < StandardError; end
    class ImportError < StandardError; end

    def initialize(client: Client.new)
      @client = client
    end

    def call(page: 1)
      page = Integer(page)

      state = SupplierSyncState.current

      state.with_lock do
        unless state.can_fetch?
          raise CooldownError,
                "LGD USA cooldown active until #{state.eligible_at}"
        end

        state.update!(last_attempt_at: Time.current)
      end

      payload = @client.fetch_jewelry(page: page)
      rows = ProductMapper.extract_rows(payload)

      if rows.empty?
        raise ImportError,
              "Supplier returned no products; nothing was changed"
      end

      # Check the supplier's reported result count.
      if payload.is_a?(Hash)
        total_results = payload["total_results"]&.to_i
        total_pages = payload["total_page"]&.to_i

        Rails.logger.info(
          "LGD USA API: page=#{page}, " \
          "total_pages=#{total_pages}, " \
          "total_results=#{total_results}, " \
          "received_rows=#{rows.size}"
        )

        # A single-page response should contain all results.
        if page == 1 &&
           total_pages == 1 &&
           total_results &&
           total_results.positive? &&
           rows.size != total_results

          raise ImportError,
                "API reported #{total_results} products, " \
                "but returned #{rows.size} records"
        end
      end

      mapped = rows.map do |row|
        ProductMapper.map(row)
      end

      duplicate_skus = mapped
        .group_by { |item| item.fetch(:stock_no) }
        .select { |_sku, items| items.size > 1 }

      if duplicate_skus.any?
        raise ImportError,
              "Supplier response contains duplicate Stock_No values: " \
              "#{duplicate_skus.keys.first(10).join(', ')}"
      end

      # Use a transaction so a failed record does not
      # leave a partially imported catalog.
      SupplierProduct.transaction do
        mapped.each do |attributes|
          product = SupplierProduct.find_or_initialize_by(
            stock_no: attributes.fetch(:stock_no)
          )

          product.assign_attributes(attributes)
          product.save!
        end
      end

      database_count = SupplierProduct.count

      Rails.logger.info(
        "LGD USA import successful: " \
        "received=#{rows.size}, " \
        "saved=#{mapped.size}, " \
        "database_total=#{database_count}"
      )

      SyncEvent.create!(
        event_type: "supplier_fetch",
        status: "success",
        message: "Imported #{mapped.size} LGD USA jewelry records " \
                 "(page #{page}). " \
                 "Database contains #{database_count} supplier products."
      )

      mapped.size

    rescue StandardError => e
      Rails.logger.error(
        "LGD USA import failed: #{e.class}: #{e.message}"
      )

      unless e.is_a?(CooldownError)
        SyncEvent.create!(
          event_type: "supplier_fetch",
          status: "error",
          message: "#{e.class}: #{e.message.to_s[0, 250]}"
        )
      end

      raise
    end
  end
end
