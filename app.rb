require 'sinatra'
require 'yandex_money/api'
require 'yaml'
require 'liquid_blocks'
#require 'liquid_inheritance'
require 'liquid'
require_relative 'liquid_path'
require_relative 'constants'

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
  liquid :index, :locals => {}
end

post '/obtain-token/' do
  scope = params[:scope]
  api = YandexMoney::Api.new(
    client_id: Constants::CLIENT_ID,
    redirect_uri: Constants::REDIRECT_URI,
    scope: scope
  )
  redirect api.client_url
end

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
