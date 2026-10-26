class CreateJewelCatalogTables < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_products do |t|
      t.string :stock_no, null: false
      t.string :title
      t.text :remarks
      t.string :category
      t.string :metal
      t.decimal :supplier_price, precision: 12, scale: 2
      t.integer :inhand_pcs, default: 0, null: false
      t.text :photo_url
      t.boolean :demo, default: false, null: false
      t.timestamps
    end

    add_index :supplier_products, :stock_no, unique: true

    create_table :catalog_settings do |t|
      t.string :vendor_name, default: "LGD USA", null: false
      t.string :title_template, default: "{remarks}", null: false
      t.text :photo_url_pattern
      t.integer :photos_per_product, default: 8, null: false
      t.string :inventory_location_label
      t.decimal :default_markup, precision: 8, scale: 2,
                default: 0, null: false
      t.jsonb :category_markups, default: {}, null: false
      t.text :sample_shopify_skus
      t.boolean :auto_sync_enabled, default: false, null: false
      t.timestamps
    end

    create_table :supplier_sync_states do |t|
      t.datetime :last_attempt_at
      t.timestamps
    end

    create_table :sync_events do |t|
      t.string :event_type, null: false
      t.string :status, null: false
      t.text :message
      t.timestamps
    end
  end
end