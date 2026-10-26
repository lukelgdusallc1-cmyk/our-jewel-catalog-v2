class SettingsController < ApplicationController
  def edit
    @settings = CatalogSetting.current
  end
  def update
    @settings = CatalogSetting.current
    if @settings.update(settings_params)
      SyncEvent.create!(event_type: 'settings', status: 'success', message: 'Local catalog settings updated')
      redirect_to edit_settings_path, notice: 'Settings saved locally.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  private
  def settings_params
    params.require(:catalog_setting).permit(:vendor_name, :title_template, :photo_url_pattern,
      :photos_per_product, :inventory_location_label, :default_markup, :sample_shopify_skus,
      category_markups: {})
  end
end
