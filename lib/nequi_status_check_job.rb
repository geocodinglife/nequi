# lib/nequi_status_check_job.rb

module Nequi
  class StatusCheckJob < Struct.new(:product_id, :configuration, :token, :code_qr)
  require 'httparty'
  require 'base64'
  require 'json'
  require 'time'
  require 'active_support/core_ext/integer/time'


    def perform
    current_time = Time.now
    utc_time = current_time.utc
    formatted_timestamp = utc_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')

      headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{:token[:access_token]}",
        'x-api-key' => configuration.api_key
      }

      body = {
        "RequestMessage" => {
          "RequestHeader" => {
            "Channel" => "PNP04-C001",
            "RequestDate" => "#{formatted_timestamp}",
            "MessageID" => "#{product_id}",
            "ClientID" => "#{configuration.client_id}",
            "Destination" => {
              "ServiceName" => "PaymentsService",
              "ServiceOperation" => "getStatusPayment",
              "ServiceRegion" => "C001",
              "ServiceVersion" => "1.0.0"
            }
          },
          "RequestBody" => {
            "any" => {
              "getStatusPaymentRQ" => {
                "codeQR": :code_qr
              }
            }
          }
        }
      }.to_json
      {

      status = 'APPROVED'

      if status == 'APPROVED'
        logs = ['Payment request approved successfully']
        Rails.logger.info(logs)
      else
      end
    end
  end
end
