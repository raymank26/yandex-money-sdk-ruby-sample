require "addressable/uri"
require 'sinatra/base'

class ExternalPayment
  #@@redirect_success_url = "http://localhost:4567/external_success_phone"
  #@@redirect_fail_url = "http://localhost:4567/external_"
  @@base_url = "http://localhost:4567"
  def initialize(api)
    @api = api
  end
  def request_payment
    @api.request_payment(request_options)
  end

  def process_payment
    @api.process_payment(process_options)
  end

  def request_options
  end

  def process_options
  end

  def sources
  end
end

class ExternalPaymentPhone < ExternalPayment
  def self.request_options(params)
    {
      :pattern_id => "phone-topup",
      :'phone-number' => params[:phone],
      :amount => params[:value]
    }
  end
  def self.urls
    {
      :post => "/external_phone/",
      :success => "/external_phone_success/",
      :fail => "/external_phone_fail/"
    }
  end

  def self.process_options(request_id)
    {
      :request_id => request_id,
      :ext_auth_success_url => @@base_url + self.urls.success,
      :ext_auth_fail_url => @@base_url + self.urls.fail
    }
  end

  def self.sources
    {
      :request => "file read here",
      :process1 => "file read here",
      :process2 => "file read here",
    }
  end
end

def make_process_payment(external_payment_class)
  Class.new(Sinatra::Base) do
    post external_payment_class.urls.post do
      request_options = external_payment_class.request_options(params)
      api = YandexMoney::Api.new(client_id: Constants::CLIENT_ID)
      response = api.get_instance_id
      api = YandexMoney::Api.new(client_id: Constants::CLIENT_ID, instance_id: response.instance_id)

      request_response = api.request_external_payment(request_options)

      process_options = external_payment_class.process_options(request_response.request_id)
      process_response = api.process_external_payment(process_options)

      uri = Addressable::Uri.new
      uri.query_values = process_response.acs_params
      redirect "#{process_response.acs_uri}?#{uri.query}"
    end
  end
end

module MobilePhone
  def self.registered(app)
    app.post "/" do
    end

    app.get "/" do
    end

    app.get "/" do
    end
  end
end

module P2pPhone
  def self.registered(app)
    app.post "/" do
    end

    app.get "/" do
    end

    app.get "/" do
    end
  end
end

make_process_payment(ExternalPaymentPhone)
