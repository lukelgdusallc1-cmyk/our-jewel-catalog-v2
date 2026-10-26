require 'set'
class CatalogSetting < ApplicationRecord
  validates :default_markup, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10000 }
  validates :photos_per_product, numericality: { only_integer: true, in: 0..20 }
  validates :title_template, :vendor_name, presence: true
  validate :valid_category_markups
  before_validation { self.auto_sync_enabled = false }

  def self.current
    first || create!
  end
  def markup_for(category)
    raw = category_markups.fetch(category.to_s, default_markup)
    BigDecimal(raw.to_s)
  rescue ArgumentError
    BigDecimal(default_markup.to_s)
  end
  def sample_sku_set
    sample_shopify_skus.to_s.split(/[\s,;]+/).map(&:strip).reject(&:blank?).map(&:upcase).to_set
  end
  private
  def valid_category_markups
    unless category_markups.is_a?(Hash) && category_markups.values.all? { |x| Float(x).between?(0, 10_000) rescue false }
      errors.add(:category_markups, 'must contain nonnegative percentages no greater than 10000')
    end
  end
end
