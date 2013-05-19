# -*- encoding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'lib/neonews'
require 'neonews_app'
require 'sidekiq/web'

map '/sidekiq' do
  run Sidekiq::Web
end

map '/' do
  run App
end