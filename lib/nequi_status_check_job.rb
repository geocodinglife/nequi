# lib/nequi_status_check_job.rb

module Nequi
  class StatusCheckJob < Struct.new(:product_id, :configuration, :token, :success_id)
    require 'httparty'
    require 'base64'
    require 'json'
    require 'time'
    require 'active_support/core_ext/integer/time'

    MAX_RETRIES = 4

    def perform
      
      @attempts ||= 0

      if @attempts >= MAX_RETRIES
        logs = { type: 'error', message: 'Job stopped due to maximum retries exceeded.' }
        Rails.logger.error(logs)
        return
      end

      @attempts += 1

      current_time = Time.now
      utc_time = current_time.utc
      formatted_timestamp = utc_time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')

      headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{token}",
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
              "ServiceOperation" => "getStatusPayment",
              "ServiceRegion" => "C001",
              "ServiceVersion" => "1.0.0"
            }
          },
          "RequestBody" => {
            "any" => {
              "getStatusPaymentRQ" => {
                "codeQR": success_id
              }
            }
          }
        }
      }.to_json

      nequi_status_payment_url = configuration.api_base_path + configuration.nequi_status_payment

      response = HTTParty.post(nequi_status_payment_url, body: body, headers: headers)


      response_status = response["ResponseMessage"]["ResponseHeader"]["Status"]
      status_code = response_status["StatusCode"]
      status_description =  response_status["StatusDesc"]

      if status_description == 'SUCCESS'
        logs = { type: 'success', status: response.code, api_status: status_code, message: 'Payment request sent successfully' }
        Rails.logger.info(logs)
      else
        StatusCheckJob.set(wait: 2.minutes).perform_later(product_id, configuration, token, success_id)
        logs = { type: 'info', message: 'Retrying the job in 2 minutes...' }
        Rails.logger.info(logs)
      end
    end
  end
end