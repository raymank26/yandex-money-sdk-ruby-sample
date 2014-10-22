require 'sinatra/base'
require 'yandex_money/api'
require_relative '../constants'
require 'pry-byebug'
require "addressable/uri"

module External
  def self.registered(app)
  end
end
