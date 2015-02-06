namespace :data do
  # {{{ desc "Generate all data files"
  desc "Generate all data files"
  multitask :generate => %w[members stores surveys] do |t, args|
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

    @REDIS.set('data-members', data.to_json)
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

    @REDIS.set('data-stores', data.to_json)
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
    members = {}
    stores = {}
    @O_APP[:member_surveys].each do |survey|
      value = survey.value
      value['key'] = survey.key
      store = stores[value['store_key']]
      store = @O_APP[:stores][value['store_key']] if store.nil?
      stores[value['store_key']] = store
      member = members[value['member_key']]
      member = @O_APP[:members][value['member_key']] if member.nil?
      members[value['member_key']] = member
      value['member'] = member.value.delete_if { |k,v| %w[password salt temp_pass temp_pass_expiry].include? k }
      value['store'] = store.value
      data << value
    end

    @REDIS.set('data-surveys', data.to_json)
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(ENV['S3_BUCKET_NAME'])
    obj = bucket.object('data-surveys.json')
    obj.put(body: data.to_json)
  end

  # }}}
end
