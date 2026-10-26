
require "set"
require "bigdecimal"

class CatalogSetting < ApplicationRecord
  validates :default_markup,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 10_000
    }

  validates :photos_per_product,
    numericality: { only_integer: true, in: 0..20 }

  validates :title_template, :vendor_name, presence: true

  before_validation :normalize_category_markups
  before_validation :disable_auto_sync

  validate :valid_category_markups

  def self.current
    first || create!
  end

  def markup_for(category)
    raw = category_markups.fetch(category.to_s, default_markup)
    BigDecimal(raw.to_s)
  rescue ArgumentError, TypeError
    BigDecimal(default_markup.to_s)
  end

  def sample_sku_set
    sample_shopify_skus.to_s
      .split(/[\s,;]+/)
      .map(&:strip)
      .reject(&:blank?)
      .map(&:upcase)
      .to_set
  end

  private

  def disable_auto_sync
    self.auto_sync_enabled = false
  end

  def normalize_category_markups
    return unless category_markups.is_a?(Hash)

    self.category_markups = category_markups.each_with_object({}) do |(category, value), result|
      next if category.to_s.strip.empty?
      next if value.nil? || value.to_s.strip.empty?

      result[category.to_s.strip] = value.to_s.strip
    end
  end

  def valid_category_markups
    unless category_markups.is_a?(Hash) &&
           category_markups.values.all? { |value| valid_percentage?(value) }
      errors.add(
        :category_markups,
        "must contain nonnegative percentages no greater than 10000"
      )
    end
  end

  def valid_percentage?(value)
    number = BigDecimal(value.to_s)
    number.finite? && number.between?(0, 10_000)
  rescue ArgumentError, TypeError
    false
  end
end
