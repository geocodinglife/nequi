# frozen_string_literal: true

require_relative "nequi/version"

module Nequi
  ERRORS_MESSAGES = {
    "20-07A": "Nequi resive the payload but got an error from them."
}

  class Error < StandardError; end
  require 'httparty'
  require 'base64'
  require 'json'
  require 'time'
  require 'active_support/core_ext/integer/time'

  include HTTParty

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :auth_uri, :phone, :auth_grant_type, :unregisteredpayment_endpoint,
                  :client_id, :client_secret, :api_base_path, :api_key, :nequi_status_payment
  end

  NEQUI_STATUS_CODE_SUCCESS = '200'.freeze

  def self.get_token
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Accept' => 'application/json',
      'Authorization' => "Basic #{Base64.strict_encode64("#{configuration.client_id}:#{configuration.client_secret}")}"
    }

    body = { 'grant_type' => configuration.auth_grant_type }

    response = HTTParty.post(configuration.auth_uri, body: body, headers: headers)

    raise "Failed to authenticate with Nequi. HTTP status code: #{response.code}" unless (response.code.to_i == 200 && !response.body.empty?)

    response_body = JSON.parse(response.body)
    @token = { access_token: response_body['access_token'], token_type: response_body['token_type'], expires_at: Time.now + 15.minutes }
  end

  def self.payment_request(amount, phone, product_id)
    current_time = Time.now
    utc_time = current_time.utc
    formatted_timestamp = utc_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')

    access_token = get_token[:access_token]

    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{access_token}",
      'x-api-key' => configuration.api_key
    }

    body = {
      "RequestMessage" => {
        "RequestHeader" => {
          "Channel" => "PNP04-C001",
          "RequestDate" => formatted_timestamp,
          "MessageID" => product_id,
          "ClientID" => configuration.client_id,
          "Destination" => {
          "ServiceName" => "PaymentsService",
          "ServiceOperation" => "unregisteredPayment",
            "ServiceRegion" => "C001",
            "ServiceVersion" => "1.2.0"
          }
        },
        "RequestBody" => {
          "any" => {
            "unregisteredPaymentRQ" => {
              "phoneNumber" => phone,
              "code" => "NIT_1",
              "value" => amount
            }
          }
        }
      }
    }.to_json

   unregisteredpayment = configuration.api_base_path + configuration.unregisteredpayment_endpoint

   response = HTTParty.post(unregisteredpayment, body: body, headers: headers)

   response_status = response["ResponseMessage"]["ResponseHeader"]["Status"]
   status_code = response_status["StatusCode"]
   status_description = response_status["StatusDesc"]


    return  {
      type: 'Error',
      status: status_code,
      message: ERRORS_MESSAGES[:"#{status_code}"] || "#{status_code} #{status_description}",
    } unless response_status == { "StatusCode" => "0", "StatusDesc" => "SUCCESS" }

    response_any = response["ResponseMessage"]["ResponseBody"]["any"]
    success_id = response_any["unregisteredPaymentRS"]["transactionId"]

    {token: access_token, success_id: success_id, type: 'success', status: response.code, api_status: status_code, message: 'Payment request send success fully'}
  end
end
