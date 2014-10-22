require 'sinatra/base'
require 'yandex_money/api'
require_relative '../constants'
require 'pry-byebug'
require "addressable/uri"

module Wallet
  def self.registered(app)
    app.get '/' do
      liquid :index
    end
    app.get '/mustache' do
      mustache :index, :locals => {
        :some => ["foo", "bar"]
      }
    end

    app.post '/obtain-token/' do
      scope = params[:scope]
      #binding.pry

      api = YandexMoney::Api.new(
        client_id: Constants::CLIENT_ID,
        redirect_uri: Constants::REDIRECT_URI,
        scope: scope
      )
      redirect api.client_url
    end

    app.get '/redirect/' do
      temp_api = YandexMoney::Api.new(
        client_id: Constants::CLIENT_ID,
        redirect_uri: Constants::REDIRECT_URI,
      )
      temp_api.code = params[:code]
      token = temp_api.obtain_token(Constants::CLIENT_SECRET)

      api = YandexMoney::Api.new(token: token)

      account_info = api.account_info
      operation_history = api.operation_history :records => 3
      request_payment = api.request_payment({
        :pattern_id => "p2p",
        :to => "410011161616877",
        :amount_due => "0.02",
        :comment => "test payment comment from yandex-money-php",
        :message => "test payment message from yandex-money-php",
        :label => "testPayment",
        :test_payment => "true",
        :test_result => "success" 
      })
      process_payment = api.process_payment({
        :request_id => request_payment.request_id,
        :test_payment => "true",
        :test_result => "success"
      })
      #binding.pry
      if operation_history.operations.size < 3
        operation_history_info = <<-eos
          You have less then 3 records in your payment history
        eos
      else
        operation_history_info = <<-eos
          The last 3 payment titles are: #{operation_history.operations[0]['title']},
          #{operation_history.operations[1]['title']}, #{operation_history.operations[2]['title']}
        eos
      end

      format_json = lambda do |open_struct|
        JSON.pretty_generate open_struct.to_h
      end

      template_meta = lambda do |method, index|
        method['includes'] = [{
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
        return method
      end

      liquid :auth, :locals => {
        'methods' => [
          {
            'info' => "You wallet balance is #{account_info.balance}",
            'code' => "code here",
            'name' => "Account-info",
            'response' => format_json.call(account_info)
          }, {
            'info' => operation_history_info,
            'code' => "code here",
            'name' => "Operation-history",
            'response' => format_json.call(operation_history)
          }, {
            'info' => "Response of request payment is successive",
            'code' => "code here",
            'name' => "Request-payment",
            'response' => format_json.call(request_payment)
          }, {
            'info' => %Q{You send #{process_payment.credit_amount} to
              #{process_payment.payee}},
            'code' => "code here",
            'name' => "Process-payment",
            'is_error' => false,
            'response' => format_json.call(process_payment)
          }
        ].map.with_index(0, &template_meta),
        'json_format_options' => "options_here",
        'parent_url' => ""
      }
    end
  end
end
