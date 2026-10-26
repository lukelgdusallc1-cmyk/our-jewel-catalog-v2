module LgdUsa
  class ProductMapper
    class Error < StandardError; end


    def self.extract_rows(payload)
      return payload if payload.is_a?(Array)

      unless payload.is_a?(Hash)
        raise Error, "Expected a JSON object or array"
      end

      # LGD USA may return an explanatory message instead of products.
      message = payload["Message"] || payload["message"]

      if message.present? && message.to_s.match?(/request.*15.minute|reached.*limit|rate.limit/i)
        raise Error, "LGD USA rate limit reached: #{message}"
      end

      # LGD USA's primary product field is Stock.
      stock = payload["Stock"] || payload["stock"]

      if stock.is_a?(Array)
        return stock
      end

      # Support other response structures as a fallback.
      %w[data products items jewelry jewellery result].each do |key|
        value = payload[key] || payload[key.capitalize]

        return value if value.is_a?(Array)

        if value.is_a?(Hash)
          rows = value.values.find { |item| item.is_a?(Array) }
          return rows if rows
        end
      end

      raise Error, "Unknown LGD USA JSON shape; no product array found"
    end


    def self.map(row)
      raise Error, "Product entry must be a JSON object" unless row.is_a?(Hash)
      data = row.transform_keys { |key| key.to_s.downcase.gsub(/[^a-z0-9]/, "") }
      sku = value(data, "stockno", "sku", "stocknumber")&.to_s&.strip
      raise Error, "Product has no Stock_No" if sku.nil? || sku.empty?

      price = value(data, "price", "supplierprice")
      quantity = value(data, "inhandpcs", "inhandpieces", "stock", "quantity")
      {
        stock_no: sku,
        title: clean_text(value(data, "title", "productname", "name")),
        remarks: clean_text(value(data, "remarks", "description")),
        category: clean_text(value(data, "category")),
        metal: clean_text(value(data, "metal", "metaltype")),
        supplier_price: decimal_or_nil(price),
        inhand_pcs: integer_or_zero(quantity),
        photo_url: clean_photo(value(data, "photourl", "imageurl", "image", "photo")),
        demo: false
      }
    end

    def self.value(data, *names)
      names.each { |name| return data[name] if data.key?(name) }
      nil
    end

    def self.clean_text(input)
      input.is_a?(String) ? input.strip.presence : nil
    end

    def self.decimal_or_nil(input)
      return nil if input.nil? || input.to_s.strip.empty?
      number = BigDecimal(input.to_s.delete(","))
      raise Error, "Negative supplier price" if number.negative?
      number
    rescue ArgumentError
      raise Error, "Invalid supplier price"
    end

    def self.integer_or_zero(input)
      return 0 if input.nil? || input.to_s.strip.empty?
      number = Integer(input.to_s)
      raise Error, "Negative supplier stock" if number.negative?
      number
    rescue ArgumentError
      raise Error, "Invalid supplier stock"
    end

    def self.clean_photo(input)
      url = input.is_a?(Array) ? input.first : input
      return nil unless url.is_a?(String)
      url.strip.start_with?("https://") ? url.strip : nil
    end
  end
end
