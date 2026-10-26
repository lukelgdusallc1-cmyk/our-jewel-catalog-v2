
# class ApplicationController < ActionController::Base
#   before_action :local_development_only!

#   private
#   def local_development_only!
#     head :forbidden unless Rails.env.development? && request.local? && %w[localhost 127.0.0.1].include?(request.host)
#   end
# end



class ApplicationController < ActionController::Base
  # layout "embedded_app"
  if Rails.env.production?
    include ShopifyApp::EnsureHasSession

    before_action :restrict_to_theia_jewels!
  else
    before_action :local_development_only!
  end

  private

  def restrict_to_theia_jewels!
    unless current_shopify_session&.shop == "theiajewels-store.myshopify.com"
      head :forbidden
    end
  end

  def local_development_only!
    head :forbidden unless Rails.env.development? &&
                           request.local? &&
                           %w[localhost 127.0.0.1].include?(request.host)
  end
end