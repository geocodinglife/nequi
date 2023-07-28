# Nequi

Nequi: Payments with Push Notification

## Installation

1. Get the keys for Nequi: [Nequi Developer Portal](https://conecta.nequi.com/?scrollspy=true)
2. Obtain a test phone number and download a testing application. This needs to be approved in the Slack channel; use the following link to join: [Nequi Development Slack Channel](https://nequidev.slack.com/join/shared_invite/enQtMzc1Njc3NzU5MTExLTMxZjRiOGRkYTQzZmJjMGMxOTdhODg3NzcwZjUzOTE2OGNkZDI4NzZhNGI1MjgzMmQ4MTg2ZDBjNDc5NWRjYWI#/shared-invite/email)

### Gems and Configuration

Add the following gems to your Gemfile:

```ruby
gem 'nequi'
gem 'dotenv-rails'
```

Then run:

```bash
bundle install
```

Create a `.env` file and add your keys to it:

```plaintext
PHONE=YourPhoneNumberHere
NEQUI_API_KEY=YourApiKeyHere
NEQUI_CLIENT_ID=YourClientIdHere
NEQUI_CLIENT_SECRET=YourClientSecretHere
NEQUI_AUTH_URI=https://oauth.sandbox.nequi.com/token
NEQUI_AUTH_GRANT_TYPE=client_credentials
NEQUI_API_BASE_PATH=https://api.sandbox.nequi.com/payments/v2
NEQUI_STATUS_PAYMENT=/-services-paymentservice-getstatuspayment
NEQUI_UNREGISTEREDPAYMENT_ENDPOINT=/-services-paymentservice-unregisteredpayment
```

Next, add the following code to your `config/initializers/nequi.rb` file:

```ruby
Nequi.configure do |config|
  config.auth_uri = ENV['NEQUI_AUTH_URI']
  config.auth_grant_type = ENV['NEQUI_AUTH_GRANT_TYPE']
  config.client_id = ENV['NEQUI_CLIENT_ID']
  config.client_secret = ENV['NEQUI_CLIENT_SECRET']
  config.api_base_path = ENV['NEQUI_API_BASE_PATH']
  config.api_key = ENV['NEQUI_API_KEY']
  config.unregisteredpayment_endpoint = ENV['NEQUI_UNREGISTEREDPAYMENT_ENDPOINT']
  config.nequi_status_payment = ENV['NEQUI_STATUS_PAYMENT']
  config.phone = ENV['PHONE']
end
```

```
  bundle exec sidekiq
```

## Usage

In your controller, you can use the following code to create a payment:

```ruby
  def create
    logs = Nequi.payment_request(params[:amount].to_i.to_s, params[:phone], params[:product_id])

    if logs[:status] == 200 && logs[:api_status] == '0'
      redirect_to payment_request_path(id: 1), {message: "Pay in nequi"}
    else
      redirect_to root_path, {message: "Error in the pition payment"}
    end
  end
```

## License

This gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
