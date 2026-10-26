module ProductContent
  class TitleBuilder
    VARIABLES = { '{remarks}' => :remarks, '{category}' => :category,
      '{metal}' => :metal, '{stockNo}' => :stock_no, '{title}' => :title }.freeze
    def initialize(settings:)
      @settings = settings
    end
    def call(product)
      text = @settings.title_template.dup
      VARIABLES.each { |key, attr| text.gsub!(key, product.public_send(attr).to_s) }
      text.squish.presence || product.display_name
    end
  end
end
