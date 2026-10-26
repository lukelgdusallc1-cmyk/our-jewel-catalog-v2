module LgdUsa
  class CatalogImporter
    class CooldownError < StandardError; end
    class ImportError < StandardError; end

    def initialize(client: Client.new)
      @client = client
    end

    def call(page: 1)
      # Single-application database lock prevents concurrent requests from bypassing cooldown.
      state = SupplierSyncState.current
      state.with_lock do
        raise CooldownError, "LGD USA cooldown active until #{state.eligible_at}" unless state.can_fetch?
        # Record the attempt BEFORE the HTTP request, including failed responses.
        state.update!(last_attempt_at: Time.current)
      end

      payload = @client.fetch_jewelry(page: page)
      rows = ProductMapper.extract_rows(payload)
      raise ImportError, "Supplier returned no products; nothing was changed" if rows.empty?

      mapped = rows.map { |row| ProductMapper.map(row) }
      duplicate_skus = mapped.group_by { |item| item[:stock_no] }.select { |_sku, items| items.size > 1 }
      raise ImportError, "Supplier response contains duplicate Stock_No values" if duplicate_skus.any?

      SupplierProduct.transaction do
        mapped.each do |attributes|
          product = SupplierProduct.find_or_initialize_by(stock_no: attributes.fetch(:stock_no))
          product.assign_attributes(attributes)
          product.save!
        end
      end
      SyncEvent.create!(event_type: "supplier_fetch", status: "success",
                        message: "Imported #{mapped.size} LGD USA jewelry records (page #{page}).")
      mapped.size
    rescue StandardError => e
      SyncEvent.create!(event_type: "supplier_fetch", status: "error", message: "#{e.class}: #{e.message.to_s[0, 250]}") unless e.is_a?(CooldownError)
      raise
    end
  end
end
