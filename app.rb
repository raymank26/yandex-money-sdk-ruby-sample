require 'sinatra/base'
require 'liquid_blocks'
require 'liquid'
require_relative 'liquid_path'
require_relative 'controllers/wallet'
require_relative 'controllers/external'

class ApplicationController < Sinatra::Base
  set :views, settings.root + "/views"
  # Enable sessions for storing token safely
  enable :sessions
  Liquid::Template.file_system = LocalFileSystem.new(File.join(File.dirname(__FILE__),'views'))

  # Change this for your application (http://www.sinatrarb.com/intro.html#Using%20Sessions)
  set :session_secret, 'mysupersecret'

  Tilt.register Tilt::LiquidTemplate, 'html'

  register Wallet # for authorized payments (OAuth2)
  register External::MobilePhone # for external payments to mobile phone
  register External::P2p # for external payments to wallet

  get '/' do
    liquid :index, :locals => {
      'lang' => 'Ruby'
    }
  end

  run! if app_file == $0
end
