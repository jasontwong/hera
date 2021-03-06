require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'typhoeus/adapters/faraday'
require 'sinatra/base'
require 'securerandom'

# {{{ class String
class String
  # {{{ def numeric?
  def numeric?
    true if Float(self) rescue false
  end

  # }}}
end

# }}}
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
      conn.adapter :typhoeus
    end
    @O_CLIENT = Orchestrate::Client.new(ENV['ORCHESTRATE_API_KEY']) do |conn|
      conn.adapter :typhoeus
    end

    @MIXPANEL_CLIENT = Mixpanel::Client.new(
      api_key: ENV['MIXPANEL_API_KEY'],
      api_secret: ENV['MIXPANEL_API_SECRET']
    )

    @APPFIGURES_CONN = Faraday.new(url: 'https://api.appfigures.com') do |f|
      f.request :url_encoded
      f.adapter :typhoeus
      f.headers = {
        'X-Client-Key' => ENV['APPFIGURES_CLIENT_KEY']
      }
      f.basic_auth(ENV['APPFIGURES_USERNAME'], ENV['APPFIGURES_PASSWORD'])
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
  # {{{ post '/emails/:key' do
  post '/emails/:key' do
    queue_item = @O_APP[:queues][params[:key]]
    halt 422 if queue_item.nil?
    ms = @O_APP[:member_surveys][queue_item['survey_key']]
    halt 422 if ms.nil?
    xhr_data = JSON.parse(request.body.read)
    unless xhr_data['test'].blank?
      clients = [
        {
          'value' => {
            'email' => xhr_data['email'],
            'permissions' => [
              "Feedback Notification",
              "Redemption Notification",
              "Dashboard",
            ]
          }
        }
      ]
    else
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
    end

    unless clients.empty?
      # {{{ merge vars
      merge_vars = []
      member = @O_APP[:members][ms['member_key']]
      store = @O_APP[:stores][ms['store_key']]
      merge_vars << {
        name: "store_name",
        content: store['name']
      }
      merge_vars << {
        name: "store_address",
        content: store['full_address']
      }
      merge_vars << {
        name: "visit_rating",
        content: ms['visit_rating']
      } unless ms['visit_rating'].nil?
      client_emails = []
      client_merge_vars = []
      clients.each do |client|
        tz = client['value']['time_zone'].blank? ? Time.zone : ActiveSupport::TimeZone.new(client['value']['time_zone'])
        permissions = client['value']['permissions'] || []
        survey_date = Time.at(ms['created_at'].to_f / 1000).in_time_zone(tz)
        if !member['attributes']['gender'].blank? && !member['attributes']['birthday'].blank?
          bday = Time.at(member['attributes']['birthday'].to_f / 1000).in_time_zone(tz)
          member_age = age(bday)
          merge_vars << {
            name: "member_data",
            content: "a #{member_age.to_s} year old #{member['attributes']['gender']}"
          }
        end

        survey_day = survey_date.strftime('%d')
        vars = [{
          name: "survey_time",
          content: survey_date.strftime('%l:%M %p'),
        },{
          name: "survey_date",
          content: survey_day.to_i.ordinalize + survey_date.strftime(' %B %Y'),
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
        tags: ['survey-emails'],
        google_analytics_domains: ['getyella.com'],
      }
      async = false
      result = @MANDRILL.messages.send_template(template_name, template_content, message, async)
    end

    queue_item.destroy! if xhr_data['test'].blank?
  end

  # }}}
  # {{{ delete '/emails/:key' do
  delete '/emails/:key' do
    queue_item = @O_APP[:queues][params[:key]]
    halt 422 if queue_item.nil?
    queue_item.destroy!
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
  # {{{ get '/data/queues/:type.:format' do
  get '/data/queues/:type.:format' do
    authorize!
    data = []
    options = {
      limit: 100,
      sort: "created_at:asc"
    }
    response = @O_CLIENT.search(:queues, "type:#{params[:type]}", options)
    response.results.each do |listing| 
      value = listing['value']
      value['key'] = listing['path']['key']
      survey = @O_APP[:member_surveys][value['survey_key']]
      value['survey'] = survey.value
      value['survey']['key'] = survey.key
      store = @O_APP[:stores][survey['store_key']]
      value['survey']['store'] = store.value
      value['survey']['store']['key'] = store.key
      member = @O_APP[:members][survey['member_key']]
      value['survey']['member'] = member.value
      value['survey']['member'].delete_if { |k,v| %w[password salt temp_pass temp_expiry].include? k }
      value['survey']['member']['key'] = member.key
      data << value
    end

    respond_to do |f|
      f.json { data.to_json }
    end
  end

  # }}}
  # {{{ get '/data/mixpanel/events' do
  get '/data/mixpanel/events' do
    authorize!
    data = @MIXPANEL_CLIENT.request(
      'events',
      event: [ params[:event] ].to_json,
      type: params[:type] || 'general',
      unit: params[:unit] || 'day',
      interval: params[:interval] || 1
    )

    respond_to do |f|
      f.json { data.to_json }
    end
  end

  # }}}
  # {{{ get '/data/appfigures/reports/sales' do
  get '/data/appfigures/reports/sales' do
    authorize!
    response = @APPFIGURES_CONN.get do |req|
      req.url '/v2/reports/sales'
      req.params['start_date'] = params['start_date']
      req.params['end_date'] = params['end_date']
      req.params['products'] = '24531418310'
      req.params['group_by'] = 'date'
      req.params['granularity'] = params['granularity'] || 'daily'
    end

    respond_to do |f|
      f.json { response.body }
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
    html += File.read(default_tpl) % ["Is this your first time here?", "Yes"] if survey['first_time']
    use_spacer = survey[:first_time]
    spacer = File.read("views/spacer.tpl.html")
    survey['answers'].each do |ans|
      question = ans['question']
      answer = ans['answer'].to_s
      html += spacer if use_spacer
      case ans['type']
      when 'star_rating'
        count = 1
        answer = '<span style="color:#FCBB50;">&#9733;</span>'

        (count...ans['answer'].to_i).each do |i|
          answer += '<span style="color:#FCBB50;padding-left:21px;">&#9733;</span>'
          count += 1
        end

        (count...5).each do |i|
          answer += '<span style="color:#D8D2CD;padding-left:21px;">&#9733;</span>'
        end
      when 'slider'
        answer += ' / 10'
      when 'switch'
        answer = answer == '1' ? 'Yes' : 'No' if answer.numeric?
        answer.capitalize!
      end

      use_spacer = true
      html += File.read(default_tpl) % [question, answer]
    end

    unless survey['comments'].blank?
      html += spacer
      html += File.read("views/comments.tpl.html") % survey['comments']
    end

    html
  end
    
  # }}}
end
