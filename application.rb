require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sass'
require 'slim'
require 'sinatra/partial'
require 'multi_json'
require 'active_support'
require 'active_support/all'
require 'rack/ssl'
require 'securerandom'
require 'orchestrate'
require 'excon'

class App < Sinatra::Base
  set(:xhr) { |xhr| condition { request.xhr? == xhr } }
  # {{{ options
  enable :sessions, :static
  set :views, 'views'
  set :protection, :except => [:session_hijacking, :json_csrf]
  register Sinatra::Partial
  set :partial_template_engine, :slim
  enable :partial_underscores
  use Rack::SSL, :exclude => lambda { |env| ENV['RACK_ENV'] != 'production' }
  # {{{ dev
  configure :development, :test do
    ENV['SESSION_SECRET'] ||= 'soix7ieph5ThieV'
    set :slim, pretty: true
    set :force_ssl, false
    enable :dump_errors, :logging
  end

  # }}}
  # {{{ prod
  configure :production do
    ENV['SESSION_SECRET'] ||= 'soix7ieph5ThieV'
    disable :logging
    enable :dump_errors
    set :bind, '0.0.0.0'
    set :port, 80
    set :force_ssl, true
    set :scss, style: :compressed, debug_info: false
  end

  # }}}
  set :session_secret => ENV['SESSION_SECRET']
  # }}}
  # {{{ defaults
  # {{{ before do
  before do
    pass if %w[css].include? request.path_info.split('/')[1]
    @O_APP = Orchestrate::Application.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
      conn.adapter :excon
    end
    @O_CLIENT = Orchestrate::Client.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
      conn.adapter :excon
    end
    Time.zone = "Central Time (US & Canada)"
  end

  # }}}
  # {{{ before xhr: false do
  before xhr: false do
    pass if %w[css].include? request.path_info.split('/')[1]
    @header_css = { all: %w[/css/screen.css] }
    @footer_js = []
    @messages = session[:messages]
    session[:messages] = nil
    @messages ||= {}
    @nav = [
      { text: 'Overview', link: '/' },
      { text: 'Users', link: '/users' },
      { text: 'Stores', link: '/stores' },
      { text: 'Surveys', link: '/surveys' },
    ]
    @title = ''
  end

  # }}}
  # {{{ get '/css/:file.css' do
  get '/css/:file.css' do
    error 404 unless File.exist? "views/scss/#{params[:file]}.scss"
    time = File.stat("views/scss/#{params[:file]}.scss").ctime
    last_modified time
    file = 'scss/' + params[:file]
    scss file.to_sym
  end

  # }}}
  # }}}
  # {{{ get '/' do
  get '/' do
    authorize!
    @title = 'Dashboard'
    slim :index
  end

  # }}}
  # {{{ get '/login' do
  get '/login' do
    redirect to('/') if authorized?
    @header_css[:all] << '/css/login.css'
    slim :login
  end

  # }}}
  # {{{ post '/login' do
  post '/login' do
    session[:authorized] = true
    redirect to('/')
  end

  # }}}
  # {{{ get '/logout' do
  get '/logout' do
    logout!
    redirect to('/')
  end

  # }}}
  private
  # {{{ def authorized?
  def authorized?
    session[:authorized]
  end

  # }}}
  # {{{ def authorize!
  def authorize!
    redirect to('/login') unless authorized?
  end

  # }}}
  # {{{ def logout!
  def logout!
    session[:authorized] = false
  end

  # }}}
end
