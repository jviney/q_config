begin
  require "active_support/core_ext/duplicable"
rescue LoadError => rails_3
  require "active_support/core_ext/object/duplicable"
end

require "active_support/core_ext/numeric/time"

class QConfig
  class Setting
    def initialize(value, options = {})
      @value, @options = value, options
    end
    
    def value
      if @value.respond_to?(:call)
        cached || cache!(@value.call)
      else
        @value.duplicable? ? @value.dup : @value
      end
    end
    
    def cached
      if @expiry && @expiry.past?
        @cached = nil
      else
        @cached
      end
    end
    
    def cache!(result)
      @expiry = @options[:expires_in].from_now if @options[:expires_in]
      @cached = result
    end
    
    def inspect
      value.inspect
    end
  end
end