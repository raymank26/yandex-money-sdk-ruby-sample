require 'sinatra'
require 'yandex_money/api'
require 'yaml'
require 'liquid_blocks'
#require 'liquid_inheritance'
require 'liquid'
require_relative 'liquid_path'
require_relative 'constants'
require 'pry-byebug'
require "addressable/uri"

configure do
  set :views, settings.root + '/views'
  # Enable sessions for storing token safely
  enable :sessions
  Liquid::Template.file_system = LocalFileSystem.new(File.join(File.dirname(__FILE__),'views'))
  puts Liquid::Template.file_system.full_path("helpers/metrica.html")

  # Change this for your application (http://www.sinatrarb.com/intro.html#Using%20Sessions)
  set :session_secret, 'mysupersecret'

  Tilt.register Tilt::LiquidTemplate, 'html'
end

# To get this data, register application at https://sp-money.yandex.ru/myservices/new.xml
get '/' do
  liquid :index
end

post '/obtain-token/' do
  scope = params[:scope]
  puts Constants::REDIRECT_URI
  api = YandexMoney::Api.new(
    client_id: Constants::CLIENT_ID,
    redirect_uri: Constants::REDIRECT_URI,
    scope: scope
  )
  redirect api.client_url
end

get '/redirect/' do
  temp_api = YandexMoney::Api.new(
    client_id: Constants::CLIENT_ID,
    redirect_uri: Constants::REDIRECT_URI,
  )
  temp_api.code = params[:code]
  token = temp_api.obtain_token(Constants::CLIENT_SECRET)
  #puts token

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
    puts operation_history.operations
    operation_history_info = <<-eos
      The last 3 payment titles are: #{operation_history.operations[0]['title']},
      #{operation_history.operations[1]['title']}, #{operation_history.operations[2]['title']}
    eos
  end

  format_json = lambda do |open_struct|
    JSON.pretty_generate open_struct.to_h
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
    ],
    'json_format_options' => "options_here",
    'parent_url' => ""
  }
end

__END__

get '/account-info' do
  api = YandexMoney::Api.new(token: session[:token])
  result = api.account_info.to_yaml
  erb :index, locals: { result: result, token: session[:token] }
end

get '/operation-history' do
  api = YandexMoney::Api.new(token: session[:token])
  if params[:records]
    result = api.operation_history(records: params[:records].to_i).to_yaml
  else
    result = api.operation_history.to_yaml
  end
  erb :index, locals: { result: result, token: session[:token] }
end

get '/request-payment' do
  api = YandexMoney::Api.new(token: session[:token])
  amount = "0.02"
  result = api.request_payment(
    pattern_id: "p2p",
    to: "410011161616877",
    amount_due: amount,
    comment: "test payment comment from yandex-money-ruby",
    message: "test payment message from yandex-money-ruby",
    label: "testPayment"
  )
  erb :index, locals: {
    result: result.to_yaml,
    token: session[:token],
    show_process_payment: true,
    request_id: result.request_id,
    amount: amount
  }
end

get '/request-payment-megafon' do
  api = YandexMoney::Api.new(token: session[:token])
  amount = "2"
  result = api.request_payment(
    pattern_id: "337",
    sum: amount,
    PROPERTY1: "921",
    PROPERTY2: "3020052",
    comment: "test payment comment from yandex-money-ruby",
    message: "test payment message from yandex-money-ruby",
    label: "testPayment"
  )
  erb :index, locals: {
    result: result.to_yaml,
    token: session[:token],
    show_process_payment: true,
    request_id: result.request_id,
    amount: amount
  }
end

get '/process-payment' do
  api = YandexMoney::Api.new(token: session[:token])
  result = api.process_payment(
    request_id: params[:request_id]
  ).to_yaml
  erb :index, locals: { result: result, token: session[:token] }
end

get '/logout' do
  session[:token] = nil
  redirect "/"
end

# OBTAINING TOKEN CODE
get '/obtain-token' do
  api = YandexMoney::Api.new(
    client_id: CONFIG[:client_id],
    redirect_uri: CONFIG[:redirect_uri],
    scope: params[:scope],
    client_secret: CONFIG[:client_secret]
  )
  redirect api.client_url
end

get '/redirect' do
  api = YandexMoney::Api.new(
    client_id: CONFIG[:client_id],
    redirect_uri: CONFIG[:redirect_uri],
    scope: params[:scope],
    client_secret: CONFIG[:client_secret]
  )
  api.code = params[:code]
  api.obtain_token
  if api.token
    session[:token] = api.token
    redirect "/"
  else
    raise 'Error obtaining token!'
  end
end
# OBTAINING TOKEN CODE
