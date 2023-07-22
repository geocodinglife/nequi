# Nequi

Nequi: Payments with Push Notification

## Installation

get the ques in Nequi: <https://conecta.nequi.com/?scrollspy=true>
also you need to get a test phone number and download a testing application
this needs to be aprobed in the slack chanel this is the link:
<https://nequidev.slack.com/join/shared_invite/enQtMzc1Njc3NzU5MTExLTMxZjRiOGRkYTQzZmJjMGMxOTdhODg3NzcwZjUzOTE2OGNkZDI4NzZhNGI1MjgzMmQ4MTg2ZDBjNDc5NWRjYWI#/shared-invite/email>

``
  gem 'nequi'

  gem 'dotenv-rails'
  
  bundle install

  create .env

  add your keys to your .env
  
  PHONE=
  NEQUI_API_KEY=
  NEQUI_CLIENT_ID=
  NEQUI_CLIENT_SECRET=
  NEQUI_AUTH_URI=<https://oauth.sandbox.nequi.com/token>
  NEQUI_AUTH_GRANT_TYPE=client_credentials
  NEQUI_API_BASE_PATH=<https://api.sandbox.nequi.com>

  add this code in your config/initializers/nequi.rb

  Nequi.configure do |config|
    config.auth_uri = ENV['NEQUI_AUTH_URI']
    config.auth_grant_type = ENV['NEQUI_AUTH_GRANT_TYPE']
    config.client_id = ENV['NEQUI_CLIENT_ID']
    config.client_secret = ENV['NEQUI_CLIENT_SECRET']
    config.api_base_path = ENV['NEQUI_API_BASE_PATH']
    config.api_key = ENV['NEQUI_API_KEY']
    config.unregisteredpayment_endpoint = ENV['NEQUI_UNREGISTEREDPAYMENT_ENDPOINT']
    config.phone = ENV['PHONE']
  end

  on the controller can be used:
    def create
      logs = Nequi.charge(params[:amount], params[:phone].to_s)
      redirect_to payment_request_url(id: 1, logs: logs)
    end
``

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
