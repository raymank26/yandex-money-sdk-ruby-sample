require 'sinatra/base'
require 'yandex_money/api'
require_relative '../constants'
require 'pry-byebug'
require "addressable/uri"
require 'yandex_money/api'

module External
  module MobilePhone
    def self.registered(app)
      app.post "/process-external/" do
        phone_number = params[:phone]
        value = params[:value]

        api_temp = YandexMoney::Api.new(
          client_id: Constants::CLIENT_ID
        )
        instance_id = api_temp.get_instance_id

        api = YandexMoney::Api.new(
          client_id: Constants::CLIENT_ID,
          instance_id: instance_id
        )

        request_result = api.request_external_payment({
          :pattern_id => 'phone-topup',
          :'phone-number' => phone_number,
          :amount => value
        })

        if request_result.status != "success"
          # throw exception
        end

        session[:request_id] = request_result.request_id
        session[:instance_id] = instance_id

        process_result = api.process_external_payment({
          :request_id => request_result.request_id,
          :ext_auth_success_uri => 'http://localhost:4567/process_external_success/',
          :ext_auth_fail_uri => 'http://localhost:4567/process_external_fail/'
        })

        session[:'result/instance_id'] = "{}"
        session[:'result/request'] = JSON.generate(request_result.to_h)
        session[:'result/process'] = JSON.generate(process_result.to_h)

        uri = Addressable::URI.new
        uri.query_values = process_result.acs_params

        redirect "#{process_result.acs_uri}?#{uri.query}"
      end

      app.get "/process_external_success/" do
        request_id = session[:request_id]
        instance_id = session[:instance_id]

        # read results
        instance_id_response = JSON.parse(session[:'result/instance_id'] || "{}")
        request_payment_response = JSON.parse(session[:'result/request'] || "{}")
        process_payment1_response = JSON.parse(session[:'result/process'] || "{}")

        api = YandexMoney::Api.new(
          client_id: Constants::CLIENT_ID,
          instance_id: instance_id
        )

        process_response = api.process_external_payment({
          :request_id => request_id,
          :ext_auth_success_uri => 'http://localhost:4567/process_external_success/',
          :ext_auth_fail_uri => 'http://localhost:4567/process_external_fail/'
        })

      format_json = lambda do |hash|
        return JSON.pretty_generate hash
      end

      template_meta = lambda do |method, index|
       [{
          "id" => index,
          "title" => "Source code",
          "is_collapsed" => false,
          "body" => method['code']
        },
        {
          "id" => index + 100,
          "title" => "Response",
          "is_collapsed" => true,
          "body" => method['response']
        }
        ]
      end

      liquid :cards, :locals => {
        "some" => "here",
        "payment_result" => process_response.to_h.stringify_keys,
        "panels" => {
          "instance_id" => template_meta.call({
            "code" => "code here",
            "response" => format_json.call(instance_id_response)
          }, 1),
          "request_payment" => template_meta.call({
            "code" => "code here",
            "response" => format_json.call(request_payment_response)
          }, 2),
          "process_payment1" => template_meta.call({
            "code" => "code here",
            "response" => format_json.call(process_payment1_response)
          }, 3),
          "process_payment2" => template_meta.call({
            "code" => "code here",
            "response" => format_json.call(process_response.to_h)
          }, 4),
        }
      }
      end

      app.post "/process_external_fail/" do
        # TODO: process fail
      end
    end
  end
end

