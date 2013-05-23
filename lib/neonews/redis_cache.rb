# http://www.ryanalynporter.com/2012/06/12/simple-redis-caching-in-ruby/
class Redis

  def cache(params)
    key = params[:key] || raise(":key parameter is required!")
    expire = params[:expire] || nil
    recalculate = params[:recalculate] || nil
    expire = params[:expire] || 86400 # 1 Day
    timeout = params[:timeout] || 5   # 5 Seconds
    default = params[:default] || nil

    if (value = get(key)).nil? || recalculate

      begin
        value = Timeout::timeout(timeout) { yield(self) }
      rescue Timeout::Error
        value = default
      end

      set(key, value)
      expire(key, expire) if expire
      value
    else
      value
    end
  end

end