
class ApplicationController < ActionController::Base
  before_action :local_development_only!

  private
  def local_development_only!
    head :forbidden unless Rails.env.development? && request.local? && %w[localhost 127.0.0.1].include?(request.host)
  end
end