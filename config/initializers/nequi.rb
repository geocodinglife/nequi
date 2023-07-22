Nequi.configure do |config|
  config.auth_uri = ENV['NEQUI_AUTH_URI']
  config.auth_grant_type = ENV['NEQUI_AUTH_GRANT_TYPE']
  config.client_id = ENV['NEQUI_CLIENT_ID']
  config.client_secret = ENV['NEQUI_CLIENT_SECRET']
  config.api_base_path = ENV['NEQUI_API_BASE_PATH']
  config.api_key = ENV['NEQUI_API_KEY']
  config.unregisteredpayment_endpoint = ENV['NEQUI_UNREGISTEREDPAYMENT_ENDPOINT']
  config.phone = ENV['PHONE']
  config.nequi_phone = ENV['NEQUI_PHONE']
end
