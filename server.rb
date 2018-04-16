
require 'sinatra'
require 'JSON'
require_relative 'keyserver.rb'
require_relative 'redis-db.rb'

# Configure the redis which we would be using for storing the keys
configure do
  REDIS = configure_redis(:prod)
end

before do
  content_type 'application/json'
end

def json_params
  begin
    JSON.parse(request.body.read)
  rescue
    halt 400, { message:'Invalid JSON' }.to_json
  end
end

keyserver = KeyServer.new(REDIS)

# Endpoints
get '/' do
  'Welcome to kashyap\'s key Server!'
  counter = REDIS.incr("request_count")
  puts "#{count}"
  {count: counter}.to_json
end

post '/keys/:count' do |count|
  puts "Generate keys"
  keyserver.create_keys(count.to_i)
  status 200
end

get '/keys' do
  puts "GET_KEY"
  free_key = keyserver.get_key
  if free_key
    status 200
    {key: free_key}.to_json
  else
    status 404
    # do we need to do this?
    {message: "No keys available"}.to_json
  end
end

post '/keys/unblock/:id' do |id|
  puts "#{id}"
  if keyserver.unblock_key(id)
    status 200
  else
    status 404
  end
end 

delete '/keys/:id' do |id|
  puts "#{id}"
  if keyserver.delete_key(id)
    status 200
  else
    status 404
  end
end

put '/keys/keep_alive/:id' do |id|
  puts "KEEP-ALIVE app #{id}"
  if keyserver.keep_alive(id)
    status 200
  else
    status 404
  end
end
