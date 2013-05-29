# -*- encoding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'bundler'
Bundler.require(:default, (ENV["RACK_ENV"]|| 'development').to_sym)

Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :size => 10}
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'] , :size => 10}
end

NEO4J_POOL = ConnectionPool.new(:size => 10, :timeout => 3) { Neography::Rest.new }
NERD_API = ENV['NERD_API'] || '1qab2v38p64api28bedp6rea8u695153'
NERD_POOL = ConnectionPool.new(:size => 10, :timeout => 3) { Nerdier::Nerd.new(NERD_API) }

#require 'ngs/models/user'
#require 'ngs/models/thing'

require 'active_support/core_ext/numeric/time'
require 'neonews/redis_cache'

require 'neonews/jobs/get_news'
require 'neonews/jobs/get_article'
require 'neonews/jobs/get_description'