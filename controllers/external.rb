require 'sinatra/base'
require 'yandex_money/api'
require_relative '../constants'
require 'pry-byebug'
require "addressable/uri"
require 'yandex_money/api'
require 'uri'

def stringify_keys(hash)
  new_hash = {}
  hash.each do |key, value|
    new_hash[key.to_s] = value
  end
  new_hash
end

def format_json(hash)
  return JSON.pretty_generate hash
end

def template_meta(method, index)
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

class URLs
  def self.relative
    {
      "mobile" => "/process-external-success/",
      "p2p" => "/wallet/process-external-success/",
      "fail" => "/process-external-fail/"
    }
  end

  def self.absolute
    hash = {}
    relative.each do |key, value|
      hash[key] = "http://localhost:4567" + value
    end
  end
end


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
          return liquid :error, :locals => {
            'text' => JSON.pretty_generate(request_result.to_h),
            'home' => '../'
          }
        end

        session[:request_id] = request_result.request_id
        session[:instance_id] = instance_id

        process_result = api.process_external_payment({
          :request_id => request_result.request_id,
          :ext_auth_success_uri => URLs::absolute['mobile'],
          :ext_auth_fail_uri => URLs::absolute['fail']
        })

        session[:'result/instance_id'] = "{}"
        session[:'result/request'] = JSON.generate(request_result.to_h)
        session[:'result/process'] = JSON.generate(process_result.to_h)

        uri = Addressable::URI.new
        uri.query_values = process_result.acs_params

        redirect "#{process_result.acs_uri}?#{uri.query}"
      end

      app.get URLs::relative['mobile'] do
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
          :ext_auth_success_uri => URLs::absolute['mobile'],
          :ext_auth_fail_uri => URLs::absolute['fail']
        })

      liquid :cards, :locals => {
        "some" => "here",
        "payment_result" => stringify_keys(process_response.to_h),
        "panels" => {
          "instance_id" => template_meta({
            "code" => "code here",
            "response" => format_json(instance_id_response)
          }, 1),
          "request_payment" => template_meta({
            "code" => "code here",
            "response" => format_json(request_payment_response)
          }, 2),
          "process_payment1" => template_meta({
            "code" => "code here",
            "response" => format_json(process_payment1_response)
          }, 3),
          "process_payment2" => template_meta({
            "code" => "code here",
            "response" => format_json(process_response.to_h)
          }, 4),
        },
        "home" => "../../",
        'lang' => 'Ruby'
      }
      end
    end
  end

  module P2p
    def self.registered(app)
      app.post "/wallet/process-external/" do
        wallet = params[:wallet]
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
          :pattern_id => 'p2p',
          :to => wallet,
          :amount_due => value,
          :comment => "sample test payment",
          :message => "sample test payment"
        })
        if request_result.status != "success"
          return liquid :error, :locals => {
            'text' => JSON.pretty_generate(request_result.to_h),
            'home' => '../../'
          }
        end

        session[:request_id] = request_result.request_id
        session[:instance_id] = instance_id

        process_result = api.process_external_payment({
          :request_id => request_result.request_id,
          :ext_auth_success_uri => URLs::absolute['p2p'],
          :ext_auth_fail_uri => URLs::absolute['fail']
        })

        session[:'result/instance_id'] = "{}"
        session[:'result/request'] = JSON.generate(request_result.to_h)
        session[:'result/process'] = JSON.generate(process_result.to_h)

        uri = Addressable::URI.new
        uri.query_values = process_result.acs_params
        redirect "#{process_result.acs_uri}?#{uri.query}"
      end

      app.get URLs::relative['p2p'] do
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
          :ext_auth_success_uri => URLs::absolute['p2p'],
          :ext_auth_fail_uri => URLs::absolute['fail']
        })


      liquid :cards, :locals => {
        "payment_result" => stringify_keys(process_response.to_h),
        "panels" => {
          "instance_id" => template_meta({
            "code" => "code here",
            "response" => format_json(instance_id_response)
          }, 1),
          "request_payment" => template_meta({
            "code" => "code here",
            "response" => format_json(request_payment_response)
          }, 2),
          "process_payment1" => template_meta({
            "code" => "code here",
            "response" => format_json(process_payment1_response)
          }, 3),
          "process_payment2" => template_meta({
            "code" => "code here",
            "response" => format_json(process_response.to_h)
          }, 4),
        },
        "home" => "../../",
        'lang' => 'Ruby'
      }
      end

      app.get URLs::relative['fail'] do
          liquid :error, :locals => {
            'text' => 'Yandex.Money redirects to fail page. Take a look at address bar',
            'home' => '../'
          }
      end
    end
  end

end

