# spec/nequi_spec.rb
require 'nequi'

RSpec.describe Nequi do
  let(:nequi_configuration) do
    Nequi::Configuration.new.tap do |config|
      config.auth_uri = 'https://example.com/auth'
      config.auth_grant_type = 'client_credentials'
      config.client_id = 'fake_client_id'
      config.client_secret = 'fake_client_secret'
      config.api_base_path = 'https://api.example.com'
      config.api_key = 'fake_api_key'
      config.phone = '3720000186'
      config.unregisteredpayment_endpoint = '/unregisteredpayment'
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
        # You can stub the HTTP response here with fake token data instead of hitting the real endpoint
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
        expect(token[:expires_at]).to be_within(1.minute).of(Time.now + 2.hours)
      end
    end

    # Add more tests to cover different scenarios, such as invalid responses, timeouts, etc.
  end

  describe '.call' do
    it 'sends a payment request and receives a successful response' do
      amount = '100000'
      phone = '3203850750'

      VCR.use_cassette('nequi_payment_success') do
        # You can stub the HTTP response here with fake response data instead of hitting the real endpoint
        allow(HTTParty).to receive(:post).and_return(
          OpenStruct.new(
            code: 200,
            body: { 'ResponseMessage' => { 'ResponseHeader' => { 'Status' => { 'StatusCode' => '200' } } } }.to_json
          )
        )

        logs = Nequi.call(amount, phone)

        expect(logs).to include({ 'type' => 'info', 'msg' => 'Ready to send Petitions' })
        expect(logs).to include({ 'type' => 'info', 'msg' => 'Petition returned HTTP 200' })
        expect(logs).to include({ 'type' => 'success', 'msg' => 'Solicitud de pago realizada correctamente' })

        # Add more expectations for the response data if needed
      end
    end

    # Add more tests to cover different scenarios, such as failed requests, invalid responses, etc.
  end
end
