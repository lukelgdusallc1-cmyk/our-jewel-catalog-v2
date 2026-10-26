class SupplierProduct < ApplicationRecord
  validates :stock_no, presence: true, uniqueness: true
  validates :inhand_pcs, numericality: { greater_than_or_equal_to: 0 }
  validates :supplier_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  def display_name
    title.presence || remarks.presence || stock_no
  end
end
