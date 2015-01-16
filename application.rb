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
require 'rack/ssl'
require 'securerandom'
require 'orchestrate'
require 'excon'
require 'aws-sdk'
require 'csv'

class App < Sinatra::Base
  register Sinatra::Contrib
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
    @footer_js << "js/vendor/d3.min.js"
    slim :index
  end

  # }}}
  # {{{ get '/data/users.:format?' do
  get '/data/users.:format' do
    authorize!
    s3 = Aws::S3::Resource.new
    begin
      bucket = s3.bucket('yella-hera')
      object = bucket.object('data-users.csv')
      response = object.get
    rescue Aws::S3::Errors::NoSuchKey => e
      csv_response = CSV.generate do |csv|
        csv << [:email, :surveys, :rewards, :store_visits]
        @O_APP[:members].each do |member|
          csv << [
            member[:email],
            member['stats']['surveys']['submitted'],
            member['stats']['rewards']['redeemed'],
            member['stats']['stores']['visits']
          ]
        end
      end
      options = {
        key: 'data-users.csv',
        body: StringIO.new(csv_response)
      }
      object = bucket.put_object(options)
      response = object.get
    end
    respond_to do |f|
      f.csv {
        stream do |out|
          response.body.read { |chunk| out << chunk }
          out.flush
        end
      }
    end
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
  # {{{ get '/users' do
  get '/users' do
    page = params[:page].blank? ? 1 : params[:page].to_i
    limit = 25
    options = {
      sort: 'name:asc',
      offset: limit * (page - 1),
      limit: limit
    }
    query = params[:query].blank? ? '*' : params[:query]
    response = @O_CLIENT.search(:members, query, options)
    response.results.each { |member| @members << Orchestrate::KeyValue.from_listing(@O_APP[:members], member, response) }
    @is_last_page = response.count < limit || limit * page == response.total_count

    slim :'users/index'
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
