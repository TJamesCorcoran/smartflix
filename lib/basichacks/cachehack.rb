# copies from 
#   /usr/lib/ruby/gems/1.8/gems/activesupport-2.3.5/lib/active_support/cache.rb
# with one change

class ActiveSupport::Cache::FileStore
  def safe_fetch(key, options = {})
    @logger_off = true

    # the one change:
    #   we should be able to store 'false' as a value
    #
    if !options[:force] && ((value = read(key, options)) != nil)
      @logger_off = false
      log("hit", key, options)
      value
    elsif block_given?
      @logger_off = false
      log("miss", key, options)
      
      value = nil
      ms = Benchmark.ms { value = yield }
      
      @logger_off = true
      write(key, value, options)
      @logger_off = false
      
      log('write (will save %.2fms)' % ms, key, nil)
      
      value
    end
  end

end


class ActiveSupport::Cache::MemoryStore
  def safe_fetch(key, options = {})
    @logger_off = true

    # the one change:
    #   we should be able to store 'false' as a value
    #
    if !options[:force] && ((value = read(key, options)) != nil)
      @logger_off = false
      log("hit", key, options)
      value
    elsif block_given?
      @logger_off = false
      log("miss", key, options)
      
      value = nil
      ms = Benchmark.ms { value = yield }
      
      @logger_off = true
      write(key, value, options)
      @logger_off = false
      
      log('write (will save %.2fms)' % ms, key, nil)
      
      value
    end
  end

end


