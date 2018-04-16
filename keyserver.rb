
require 'securerandom'
class KeyServer
  KEY_LIMIT = 10000
  KEY_EXPIRE = 300
  BLOCK_LIMIT = 60

  def initialize(redis_obj)
    @redis = redis_obj
    # keeps count of the total keys in use
    @keys = 0
  end

  def clean_expired_keys
    expired_keys = @redis.smembers("available_keys").select { |key| !@redis.exists(key) }
    # There is an issue with the redis api for srem when called on a empty array Exception for invalid no. of arguements thrown
    if expired_keys.size != 0
      @redis.srem("available_keys", expired_keys)
    end
    expired_keys = @redis.smembers("blocked_keys").select { |key| !@redis.exists(key) }
    if expired_keys.size != 0
      @redis.srem("blocked_keys", expired_keys)
    end
    @keys = @redis.scard("available_keys") + @redis.scard("blocked_keys")
  end

  def create_keys(n_keys)
    keys_created = 0
    while @keys < KEY_LIMIT and keys_created < n_keys
      key = SecureRandom.hex.to_s
      # we insert the key is not already there
      if @redis.set(key, Time.now.to_i.to_s, {:ex => KEY_EXPIRE, :nx => true})
        @redis.sadd("available_keys", key)
        keys_created += 1
      end
    end
  end

  def get_key
    key = @redis.spop("available_keys")
    if key.nil?
      return false
    end
    @redis.setex(key, 300, Time.now.to_i.to_s)
    @redis.sadd("blocked_keys", key)
    key
  end

  def unblock_key(key)
    # No special handling, we just don't add it to the available_keys unless we were able to remove it from the blocked_keys successfully
    if @redis.srem("blocked_keys", key)
      @redis.sadd("available_keys", key)
    else 
      return false
    end
  end

  def delete_key(key)
    if @redis.del(key)
      @redis.srem("blocked_keys", key)
      @redis.srem("available_keys", key)
    else
      return false
    end
  end

  def keep_alive(key)
    return @redis.set(key, Time.now.to_i.to_s, {:ex => KEY_EXPIRE, :xx => true})
  end

  def unblock_cron
    clean_expired_keys
    @redis.smembers("blocked_keys").each do |key|
      unblock_key(key) if (Time.now.to_i - @redis.get(key).to_i) > BLOCK_LIMIT
    end
  end
end