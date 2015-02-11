require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'sinatra/base'
require 'securerandom'

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

    redis_url = ENV["REDISCLOUD_URL"] || ENV["OPENREDIS_URL"] || ENV["REDISGREEN_URL"] || ENV["REDISTOGO_URL"]
    @REDIS = Redis::Namespace.new("yella:hera", redis: Redis.new(url: redis_url))
    @MANDRILL = Mandrill::API.new
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
  # {{{ post '/send_feedback' do
  post '/send_feedback' do
    queue_item = @O_APP[:queues][params[:queue_key]]
    halt 422 if queue_item.nil?
    ms = @O_APP[:member_surveys][queue_item['survey_key']]
    halt 422 if ms.nil?
    clients = []
    query = "store_keys:#{ms['store_key']} AND permissions:\"Feedback Notification\""
    options = {
      limit: 100
    }
    response = @O_CLIENT.search(:clients, query, options)
    loop do
      clients += response.results
      response = response.next_results
      break if response.nil?
    end

    unless clients.empty?
      # {{{ merge vars
      merge_vars = []
      member = @O_APP[:members][ms['member_key']]
      merge_vars << {
        name: "member_gender",
        content: member['attributes']['gender'].nil? ? 'Other' : member['attributes']['gender'].titlecase
      }
      merge_vars << {
        name: "visit_rating",
        content: ms['visit_rating']
      } unless ms['visit_rating'].nil?
      merge_vars << {
        name: "comment",
        content: ms['comment']
      } unless ms['comment'].blank?
      client_emails = []
      client_merge_vars = []
      clients.each do |client|
        tz = client['value']['time_zone'].nil? ? Time.zone : ActiveSupport::TimeZone.new(client['value']['time_zone'])
        permissions = client['value']['permissions'] || []
        survey_date = Time.at(ms['created_at'].to_f / 1000).in_time_zone(tz)
        member_age = 'Unknown'
        if bday = member['attributes']['birthday']
          bday = Time.at(bday.to_f / 1000).in_time_zone(tz)
          member_age = age(bday)
        end

        vars = [{
          name: "survey_time",
          content: survey_date.strftime('%l:%M%p'),
        },{
          name: "survey_date",
          content: survey_date.strftime('%m/%d/%y'),
        },{
          name: "member_age",
          content: member_age,
        }]
        vars << {
          name: "launch_dashboard",
          content: true
        } if permissions.include?('Dashboard')
        client_emails << { email: client['value']['email'] }
        client_merge_vars << { rcpt: client['value']['email'], vars: merge_vars + vars }
      end

      # }}}
      # send email
      template_name = "new-survey"
      template_content = [{
        name: "questions",
        content: display_questions(ms)
      }]
      message = {
        to: client_emails,
        from_email: "merchantsupport@getyella.com",
        headers: {
          "Reply-To" => "merchantsupport@getyella.com",
        },
        preserve_recipients: false,
        important: true,
        track_opens: true,
        track_clicks: true,
        url_strip_qs: true,
        merge_vars: client_merge_vars,
        tags: ['survey-feedback'],
        google_analytics_domains: ['getyella.com'],
      }
      async = false
      result = @MANDRILL.messages.send_template(template_name, template_content, message, async)
    end
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
    key = "data-#{params[:type]}"
    begin
      data = @REDIS.get(key)
    rescue Redis::CannotConnectError => e
    end
    if data.blank?
      s3 = Aws::S3::Resource.new
      bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
      object = bucket.object("#{key}.#{params[:format]}")
      response = object.get
      data = response.body.read
      begin
        @REDIS.set(key, data)
      rescue Redis::CannotConnectError => e
      end
    end

    respond_to do |f|
      f.json { data }
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
  # {{{ def age(dob)
  def age(dob)
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end
    
  # }}}
  # {{{ def display_questions(survey)
  def display_questions(survey)
    html = ""
    default_tpl = "views/question.tpl.html"
    if survey['first_time']
      html += File.read(default_tpl) % ["Is this your first time here?", "Yes"]
    end

    red = false
    survey['answers'].each do |ans|
      question = ans['question']
      answer = ans['answer'].to_s
      if ans['type'] == 'star_rating'
        answer = red ? '<span style="color:#e65142;">' : '<span>'
        (0...5).each { |i| answer += i <= ans['answer'] ? "&#9733;" : "&#9734;" }
        answer += "</span>"
        red = !red
      end

      html += File.read(default_tpl) % [question, answer]
    end

    html
  end
    
  # }}}
end
