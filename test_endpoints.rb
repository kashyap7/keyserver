
# test endpoints
require 'redis'
require_relative 'keyserver.rb'
require_relative 'redis-db.rb'
REDIS = configure_redis(:test)

keyserver_test = KeyServer.new(REDIS)

puts keyserver_test.create_keys(50)
keyserver_test.clean_expired_keys
keyserver_test.delete_key("fakekey")
