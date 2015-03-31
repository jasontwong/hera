namespace :data do
  # {{{ desc "Generate all data files"
  desc "Generate all data files"
  multitask :generate => %w[members stores surveys checkins companies redeems] do |t, args|
  end

  # }}}
  # {{{ desc "Generate member data files"
  desc "Generate member data files"
  task :members do
    query = "*"
    options = {
      limit: 100
    }
    data = []
    @O_APP[:members].each do |member|
      value = member.value
      value['key'] = member.key
      data << value.delete_if { |k,v| %w[password salt temp_pass temp_expiry].include? k }
    end

    begin
      @REDIS.set('data-members', data.to_json)
    rescue Redis::CannotConnectError => e
    end
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-members.json')
    obj.put(body: data.to_json)
  end

  # }}}
  # {{{ desc "Generate store data files"
  desc "Generate store data files"
  task :stores do
    query = "*"
    options = {
      limit: 100
    }
    data = []
    @O_APP[:stores].each do |store|
      value = store.value
      value['key'] = store.key
      data << value
    end

    begin
      @REDIS.set('data-stores', data.to_json)
    rescue Redis::CannotConnectError => e
    end
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-stores.json')
    obj.put(body: data.to_json)
  end

  # }}}
  # {{{ desc "Generate survey data files"
  desc "Generate survey data files"
  task :surveys do
    query = "*"
    options = {
      limit: 100
    }
    data = []
    @O_APP[:member_surveys].each do |survey|
      value = survey.value
      value['key'] = survey.key
      data << value
    end

    begin
      @REDIS.set('data-surveys', data.to_json)
    rescue Redis::CannotConnectError => e
    end
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-surveys.json')
    obj.put(body: data.to_json)
  end

  # }}}
  # {{{ desc "Generate checkin data files"
  desc "Generate checkin data files"
  task :checkins do
    query = "*"
    options = {
      limit: 100
    }
    data = []
    @O_APP[:checkins].each do |checkin|
      value = checkin.value
      value['key'] = checkin.key
      data << value
    end

    begin
      @REDIS.set('data-checkins', data.to_json)
    rescue Redis::CannotConnectError => e
    end
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-checkins.json')
    obj.put(body: data.to_json)
  end

  # }}}
  # {{{ desc "Generate company data files"
  desc "Generate company data files"
  task :companies do
    query = "*"
    options = {
      limit: 100
    }
    data = []
    @O_APP[:companies].each do |company|
      value = company.value
      value['key'] = company.key
      loop do
        response = @O_CLIENT.search(:rewards, "company_key:#{company.key} AND active:true")
        rewards = []
        response.results.each do |reward|
          r = reward['value']
          r[:key] = reward['path']['key']
          r.delete_if { |k, v| ['active', 'company_key'].include? k }
          rewards << r
        end

        value['rewards'] = rewards.sort { |a,b| a['cost'] <=> b['cost'] }
        response = response.next_results
        break if response.nil?
      end

      data << value
    end

    begin
      @REDIS.set('data-companies', data.to_json)
    rescue Redis::CannotConnectError => e
    end
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-companies.json')
    obj.put(body: data.to_json)
  end

  # }}}
  # {{{ desc "Generate redeem data files"
  desc "Generate redeem data files"
  task :redeems do
    query = "*"
    options = {
      limit: 100
    }
    data = []
    @O_APP[:redeems].each do |redeem|
      value = redeem.value
      value['key'] = redeem.key
      data << value
    end

    begin
      @REDIS.set('data-redeems', data.to_json)
    rescue Redis::CannotConnectError => e
    end
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-redeems.json')
    obj.put(body: data.to_json)
  end

  # }}}
end
