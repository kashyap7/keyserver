
require 'REDIS'
require 'uri'
PORT = 6379
DB_ENV = {
  :prod => 0,
  :test => 1
}
def configure_redis(env)
  redistogo_url = "redis://localhost:#{PORT}/"
  uri = URI.parse(redistogo_url)
  redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  redis.select(DB_ENV[env])
  return redis
end
