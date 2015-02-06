require "rubygems"
require "bundler/setup"
require 'orchestrate'
require 'excon'
require 'aws-sdk'
require 'rake/benchmark' if ENV['RACK_ENV'] == 'development'
require 'redis-namespace'

Dir.glob('lib/tasks/**/*.rake').each { |r| load r}

@O_APP = Orchestrate::Application.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
  conn.adapter :excon
end
@O_CLIENT = Orchestrate::Client.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
  conn.adapter :excon
end
redis_url = ENV["REDISCLOUD_URL"] || ENV["OPENREDIS_URL"] || ENV["REDISGREEN_URL"] || ENV["REDISTOGO_URL"]
@REDIS = Redis::Namespace.new("yella:hera", redis: Redis.new(url: redis_url))
