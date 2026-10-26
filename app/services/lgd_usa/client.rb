require "net/http"
require "json"

module LgdUsa
  class Client
    class Error < StandardError; end

    def initialize
      @url = ENV.fetch("LGD_USA_API_URL")
      @api_key = ENV.fetch("LGD_USA_API_KEY")
    end

    def fetch_jewelry(page: 1)
      uri = URI.parse(@url)

      uri.query = URI.encode_www_form(
        type: "all",
        page: page,
        key: @api_key
      )

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 10,
        read_timeout: 30
      ) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Supplier returned HTTP #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, "Supplier returned invalid JSON"
    end
  end
end