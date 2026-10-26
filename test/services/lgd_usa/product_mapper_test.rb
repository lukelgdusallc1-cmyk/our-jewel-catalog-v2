require "test_helper"

class LgdUsaProductMapperTest < ActiveSupport::TestCase
  test "maps supplier data" do
    mapped = LgdUsa::ProductMapper.map({"Stock_No" => "ABC123", "Remarks" => "Diamond Ring", "Category" => "Rings", "Price" => "125.50", "Inhand_Pcs" => "2"})
    assert_equal "ABC123", mapped[:stock_no]
    assert_equal 2, mapped[:inhand_pcs]
    assert_equal BigDecimal("125.50"), mapped[:supplier_price]
  end
  test "rejects unknown response structure" do
    assert_raises(LgdUsa::ProductMapper::Error) { LgdUsa::ProductMapper.extract_rows({"unexpected" => "value"}) }
  end
end
