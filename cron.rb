
require_relative 'keyserver.rb'
require_relative 'redis-db.rb'

keyserver = KeyServer.new(configure_redis(:prod))

while true
  keyserver.unblock_cron
  sleep 1
end
