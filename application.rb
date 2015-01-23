require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/contrib/all'
require 'sass'
require 'slim'
require 'sinatra/partial'
require 'multi_json'
require 'active_support'
require 'active_support/all'
require 'securerandom'
require 'orchestrate'
require 'excon'
require 'aws-sdk'
require 'csv'

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
    @header_css[:all] << '/css/login.css'
    slim :login
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
  # {{{ get '/members' do
  get '/members' do
    authorize!
    @title = 'Members'
    @footer_js << '/js/members.index.js'
    page = params[:page].blank? ? 1 : params[:page].to_i
    limit = 25
    options = {
      sort: 'email:asc',
      offset: limit * (page - 1),
      limit: limit
    }
    @members = []
    query = params[:query].blank? ? '*' : params[:query]
    response = @O_CLIENT.search(:members, query, options)
    response.results.each { |member| @members << Orchestrate::KeyValue.from_listing(@O_APP[:members], member, response) }
    @is_last_page = response.count < limit || limit * page == response.total_count
    @stats = {}
    response = @O_CLIENT.search(:members, "stats.stores.visits:[1 TO *]", { limit: 1 })
    @stats[:visits] = response.total_count || response.count
    response = @O_CLIENT.search(:members, "stats.rewards.redeemed:[1 TO *]", { limit: 1 })
    @stats[:redeemed] = response.total_count || response.count
    response = @O_CLIENT.search(:members, "stats.surveys.submitted:[1 TO *]", { limit: 1 })
    @stats[:active] = response.total_count || response.count
    response = @O_CLIENT.search(:members, "*", { limit: 1 })
    @stats[:total] = response.total_count || response.count

    slim :'members/index'
  end

  # }}}
  # {{{ get '/stores' do
  get '/stores' do
    authorize!
    @title = 'Stores'
    @footer_js << '/js/stores.index.js'
    page = params[:page].blank? ? 1 : params[:page].to_i
    limit = 25
    options = {
      sort: 'name:asc',
      offset: limit * (page - 1),
      limit: limit
    }
    @stores = []
    query = "stats.surveys.submitted:0 AND active:true"
    query += " AND #{params[:query]}" unless params[:query].blank?
    response = @O_CLIENT.search(:stores, query, options)
    response.results.each { |store| @stores << Orchestrate::KeyValue.from_listing(@O_APP[:stores], store, response) }
    @is_last_page = response.count < limit || limit * page == response.total_count
    @stats = {}
    @stats[:no_visits] = response.total_count || response.count
    response = @O_CLIENT.search(:stores, "active:true", { limit: 1 })
    @stats[:active] = response.total_count || response.count
    response = @O_CLIENT.search(:stores, "*", { limit: 1 })
    @stats[:total] = response.total_count || response.count

    slim :'stores/index'
  end

  # }}}
  # {{{ get '/surveys' do
  get '/surveys' do
    authorize!
    @title = 'Surveys'
    @footer_js << '/js/surveys.index.js'
    page = params[:page].blank? ? 1 : params[:page].to_i
    limit = 25
    options = {
      sort: 'completed_at:desc',
      offset: limit * (page - 1),
      limit: limit
    }
    @surveys = []
    query = "completed:true"
    query += " AND #{params[:query]}" unless params[:query].blank?
    response = @O_CLIENT.search(:member_surveys, query, options)
    response.results.each { |survey| @surveys << Orchestrate::KeyValue.from_listing(@O_APP[:surveys], survey, response) }
    @is_last_page = response.count < limit || limit * page == response.total_count
    @stats = {}
    @stats[:completed] = response.total_count || response.count
    response = @O_CLIENT.search(:member_surveys, "*", { limit: 1 })
    @stats[:total] = response.total_count || response.count

    slim :'surveys/index'
  end

  # }}}
  # data service endpoints
  # {{{ get '/data/:type.:format' do
  get '/data/:type.:format' do
    authorize!
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket('yella-hera')
    object = bucket.object("data-#{params[:type]}.#{params[:format]}")
    response = object.get
    respond_to do |f|
      f.csv { response.body.read }
    end
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
