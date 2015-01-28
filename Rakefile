require "rubygems"
require "bundler/setup"
require 'orchestrate'
require 'excon'
require 'aws-sdk'
require 'rake/benchmark' if ENV['RACK_ENV'] == 'development'

Dir.glob('lib/tasks/**/*.rake').each { |r| load r}

@O_APP = Orchestrate::Application.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
  conn.adapter :excon
end
@O_CLIENT = Orchestrate::Client.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
  conn.adapter :excon
end
