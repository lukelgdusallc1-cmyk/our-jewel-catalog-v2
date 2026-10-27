
class SupplierFetchesController < ApplicationController
  def index
    @state = SupplierSyncState.current
  end

  def create
    unless Rails.env.production? || (Rails.env.development? && request.local?)
      return head :forbidden
    end

    count = LgdUsa::CatalogImporter.new.call

    redirect_to supplier_fetches_path,
      notice: "Imported #{count} supplier products."

  rescue LgdUsa::CatalogImporter::CooldownError => e
    redirect_to supplier_fetches_path, alert: e.message

  rescue StandardError => e
    Rails.logger.error("LGD USA fetch failed: #{e.class}: #{e.message}")
    redirect_to supplier_fetches_path,
      alert: "Supplier import failed. Check History and Rails logs."
  end
end
