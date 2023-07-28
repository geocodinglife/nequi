# spec/nequi_spec.rb
require 'nequi'

RSpec.describe Nequi do
  let(:nequi_configuration) do
    Nequi::Configuration.new.tap do |config|
      config.auth_uri = 'https://example.com/auth'
      config.auth_grant_type = 'client_credentials'
      config.client_id = 'fake_client_id'
      config.client_secret = 'fake_client_secret'
      config.api_base_path = 'https://api.sandbox.nequi.com/payments/v2'
      config.api_key = 'fake_api_key'
      config.phone = '3720000168'
      config.unregisteredpayment_endpoint = '/-services-paymentservice-unregisteredpayment'
    end
  end

  before do
    Nequi.configure do |config|
      config.auth_uri = nequi_configuration.auth_uri
      config.auth_grant_type = nequi_configuration.auth_grant_type
      config.client_id = nequi_configuration.client_id
      config.client_secret = nequi_configuration.client_secret
      config.api_base_path = nequi_configuration.api_base_path
      config.api_key = nequi_configuration.api_key
      config.unregisteredpayment_endpoint = nequi_configuration.unregisteredpayment_endpoint
    end
  end

  describe '.get_token' do
    it 'returns a valid token' do
      VCR.use_cassette('nequi_token') do
        allow(HTTParty).to receive(:post).and_return(
          OpenStruct.new(
            code: 200,
            body: { 'access_token' => 'fake_access_token', 'token_type' => 'Bearer' }.to_json
          )
        )

        token = Nequi.get_token
        expect(token).not_to be_nil
        expect(token[:access_token]).not_to be_nil
        expect(token[:token_type]).to eq('Bearer')
        expect(token[:expires_at]).to be_within(15.minutes).of(Time.now + 15.minutes)
      end
    end

    it 'raises an error when failing to authenticate with Nequi' do
      VCR.use_cassette('nequi_token_failed_authentication') do
        allow(HTTParty).to receive(:post).and_return(
          OpenStruct.new(
            code: 401, # Unauthorized status code
            body: '' # Empty response body to simulate authentication failure
          )
        )

        expect { Nequi.get_token }.to raise_error(RuntimeError, /Failed to authenticate with Nequi/)
      end
    end

    # Add more tests to cover different scenarios for token retrieval.
  end

  describe '.payment_request' do
    it 'sends a payment request and receives a successful response' do
      amount = '100000'
      phone = '3203850750'
      product_id = 'fake_product_id'

      VCR.use_cassette('nequi_payment_success') do
        allow(Nequi).to receive(:get_token).and_return(
          { access_token: 'fake_access_token', token_type: 'Bearer', expires_at: Time.now + 15.minutes }
        )

        # Stub the HTTP response for payment request
        allow(HTTParty).to receive(:post).and_return(
          OpenStruct.new(
            code: 200,
            body: {
              'ResponseMessage' => {
                'ResponseHeader' => { 'Status' => { 'StatusCode' => '0', 'StatusDesc' => 'SUCCESS' } },
                'ResponseBody' => { 'any' => { 'unregisteredPaymentRS' => { 'transactionId' => 'fake_transaction_id' } } }
              }
            }.to_json
          )
        )

        logs = Nequi.payment_request(amount, phone, product_id)

        expect(logs).to include({ 'type' => 'success', 'status' => 200, 'api_status' => '0', 'message' => 'Payment request send success fully' })
        # Add more expectations for the response data if needed
      end
    end

    it 'returns an error when the payment request fails' do
      amount = '100000'
      phone = '3203850750'
      product_id = 'fake_product_id'

      VCR.use_cassette('nequi_payment_failure') do
        allow(Nequi).to receive(:get_token).and_return(
          { access_token: 'fake_access_token', token_type: 'Bearer', expires_at: Time.now + 15.minutes }
        )

        # Stub the HTTP response for a failed payment request
        allow(HTTParty).to receive(:post).and_return(
          OpenStruct.new(
            code: 200,
            body: {
              'ResponseMessage' => {
                'ResponseHeader' => { 'Status' => { 'StatusCode' => '1', 'StatusDesc' => 'FAILED' } },
                'ResponseBody' => { 'any' => { 'unregisteredPaymentRS' => { 'transactionId' => nil } } }
              }
            }.to_json
          )
        )

        logs = Nequi.payment_request(amount, phone, product_id)

        expect(logs).to include({ 'type' => 'Error', 'status' => 200, 'api_status' => '1', 'message' => 'FAILED' })
        # Add more expectations for the error response if needed
      end
    end

    # Add more tests to cover different scenarios for payment requests.
  end
end
