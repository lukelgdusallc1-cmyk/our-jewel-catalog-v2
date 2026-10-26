Rails.application.config.session_store(
  :cookie_store,
  key: "_our_jewel_catalog_v2_session",
  expire_after: 14.days,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
)