# LGD USA integration (V2)

The code has been added to the existing V2 project in:
- app/services/lgd_usa/client.rb (existing client, unchanged)
- app/services/lgd_usa/product_mapper.rb (new, validates supplier fields)
- app/services/lgd_usa/catalog_importer.rb (new implementation)
- app/controllers/supplier_fetches_controller.rb (connects Fetch button)
- app/views/supplier_fetches/index.html.erb (status and guarded button)
- test/services/lgd_usa/product_mapper_test.rb (offline tests)

## Configuration
Keep in your **local** `.env.local` (excluded from this archive):

LGD_USA_API_URL=https://lgdusallc.com/developer-api/jewelry
LGD_USA_API_KEY=your_private_key

Never commit or share your key. Rotate the previously disclosed key if possible.

## Run
1. Back up the V2 Rails project.
2. Merge only the modified/new files from this ZIP into your existing project.
3. Run `bin/rails test test/services/lgd_usa/product_mapper_test.rb`.
4. Start `bin/rails server -b 127.0.0.1` and open `http://localhost:3000/supplier_fetches`.
5. Trigger one fetch only after verifying supplier permissions and rate limits.

## Limitations
The response wrapper has not been verified against a live LGD USA response. The importer rejects unknown shapes, empty responses, invalid rows and duplicate SKUs instead of making unsafe assumptions. It fetches only page 1. Source image mapping is preliminary. Rate limiting is database-backed for this application, not shared with other apps using the same supplier key. No Shopify API requests or writes occur. The Fetch POST is restricted to local development requests until Shopify authentication is implemented.
