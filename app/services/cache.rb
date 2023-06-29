# Mocking the Cache
class Cache
  def self.get(_key)
    'pending'
  end

  def self.set(key, value); end

  def self.setex(key, ttl, url); end
end
