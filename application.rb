require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sass'
require 'slim'
require 'sinatra/partial'
require 'multi_json'
require 'active_support/all'
require 'securerandom'
require 'orchestrate'
require 'excon'
require 'aws-sdk'
require 'coffee-script'

class App < Sinatra::Base
  register Sinatra::Contrib
  set(:xhr) { |xhr| condition { request.xhr? == xhr } }
  # {{{ options
  enable :static
  set :views, 'views'
  register Sinatra::Partial
  set :partial_template_engine, :slim
  enable :partial_underscores
  # {{{ dev
  configure :development, :test do
    set :slim, pretty: true
    enable :dump_errors, :logging
  end

  # }}}
  # {{{ prod
  configure :production do
    disable :logging
    enable :dump_errors
    set :bind, '0.0.0.0'
    set :port, 80
    set :scss, style: :compressed, debug_info: false
    set session_secret: ENV['SESSION_SECRET'] || 'OT1aesheg4iush0eboa0kahc5'
  end

  # }}}
  use Rack::Session::Cookie, :key => 'analytics.getyella.com',
     :path => '/',
     :expire_after => 2592000, # In seconds
     :secret => ENV['SESSION_SECRET'] || 'OT1aesheg4iush0eboa0kahc5'
  set :protection, :except => [:json_csrf]
  
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
      { text: 'Members', link: '/members' },
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
  # {{{ get '/js/:file.js' do
  get '/js/:file.js' do
    error 404 unless File.exist? "views/coffee/#{params[:file]}.coffee"
    time = File.stat("views/coffee/#{params[:file]}.coffee").ctime
    last_modified time
    file = 'coffee/' + params[:file]
    content_type "text/javascript"
    coffee file.to_sym
  end

  # }}}
  # }}}
  # {{{ get '/' do
  get '/' do
    authorize!
    @title = 'Overview'
    @header_css[:all] << '/css/dc.css'
    @footer_js << '/js/vendor/spin.min.js'
    @footer_js << '/js/vendor/crossfilter.min.js'
    @footer_js << '/js/vendor/dc.min.js'
    @footer_js << '/js/dashboard.index.js'
    slim :index
  end

  # }}}
  # {{{ get '/login' do
  get '/login' do
    redirect to('/') if authorized?
    slim :login, layout: :layout_login
  end

  # }}}
  # {{{ post '/login' do
  post '/login' do
    session[:authorized] = params[:username] == 'yella' && params[:password] == 'ECK5A91pb2nO'
    redirect to('/')
  end

  # }}}
  # {{{ get '/logout' do
  get '/logout' do
    logout!
    redirect to('/')
  end

  # }}}
  # {{{ get '/tpl/:type/?:page?.html' do
  get '/tpl/:type/?:page?.html' do
    authorize!
    page = params[:page].blank? ? params[:type] : "#{params[:type]}/#{params[:page]}"
    slim :"#{page}", layout: false
  end

  # }}}
  # data service endpoints
  # {{{ get '/data/:type.:format' do
  get '/data/:type.:format' do
    authorize!
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    object = bucket.object("data-#{params[:type]}.#{params[:format]}")
    response = object.get
    respond_to do |f|
      f.csv { response.body.read }
      f.json { response.body.read }
    end
  end

  # }}}
  # catch all routes
  # {{{ get '/*' do
  get '/*' do
    authorize!
    slim :index
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
