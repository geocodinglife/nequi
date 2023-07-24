# frozen_string_literal: true

require_relative "nequi/version"

module Nequi
  class Error < StandardError; end
  require 'securerandom'
  require 'httparty'
  require 'base64'
  require 'json'
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
                  :client_id, :client_secret, :api_base_path, :api_key
  end

  NEQUI_STATUS_CODE_SUCCESS = '200'.freeze

  def self.get_token
    return @token if @token

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

  def self.charge(amount, phone)
    current_time = Time.now
    formatted_timestamp = current_time.strftime('%Y-%m-%d %H:%M:%S.%6N %z')
    message_id = SecureRandom.uuid

    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{get_token[:access_token]}",
      'x-api-key' => configuration.api_key
    }

    body = {
      "RequestMessage" => {
        "RequestHeader" => {
          "Channel" => "PNP04-C001",
          "RequestDate" => formatted_timestamp,
          "MessageID" => message_id,
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

    logs = [{ 'type' => 'information', 'message' => "Ready to send Petitions" }]

    unregisteredpayment = configuration.api_base_path + configuration.unregisteredpayment_endpoint

    response = HTTParty.post(unregisteredpayment, body: body, headers: headers)

    response_body = JSON.parse(response.body)

    if response.code.to_i == 200 && !response_body['ResponseMessage']['ResponseBody'].nil?
      logs << { 'type' => 'information', 'message' => "Petition returned HTTP 200" }

      begin
        any_data = response_body['ResponseMessage']['ResponseBody']['any']

        status = response_body['ResponseMessage']['ResponseHeader']['Status']
        status_code = status ? status['StatusCode'] : ''
        status_desc = status ? status['StatusDesc'] : ''

        if status_code == '200'
          logs << { 'type' => 'success', 'message' => 'Payment request send success fully' }

          payment = any_data['unregisteredPaymentRS']
          trn_id = payment ? payment['transactionId'].to_s.strip : ''

          logs << { 'type' => 'success', 'message' => 'Transaction Id: ' + trn_id }
        else
          raise 'Error ' + status_code + ' = ' + status_desc
        end

      rescue StandardError => e
        raise e
      end
    else
      raise 'Unable to connect to Nequi, please check the information sent.'
    end

    logs
  end
end
