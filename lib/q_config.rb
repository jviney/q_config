require "active_support/core_ext/hash/indifferent_access"

require "q_config/setting"

class QConfig
  (instance_methods + private_instance_methods).each do |m|
    undef_method(m) if m.to_s !~ /(?:^__|^nil\?$|^send$|^object_id$|^instance_eval$|^class$|^eval$|^initialize$|^raise$)/
  end
  
  def initialize(&block)
    instance_eval(&block) if block
  end
  
  def source(path)
    __sources << path
    __parse_file path
  end
  
  def reset
    __settings.clear
    __sources.each { |path| __parse_file(path) }
  end

  def namespace(name, &block)
    name = name.to_s
    __settings[name] ||= QConfig.new
    __settings[name].instance_eval(&block)
    __settings[name]
  end
  
  def method_missing(*args, &block)
    key = args.shift
    
    if args.empty?
      __get(key)
    else
      __set(key, *args, &block)
    end
  end
  
  def to_hash
    __settings.inject({}.with_indifferent_access) do |hash, (key, value)|
      if Setting === value
        hash[key] = value.value
      else
        hash[key] = value.to_hash
      end
      hash
    end
  end
  
  def include?(key)
    __settings.include?(key.to_s)
  end
  
  def inspect
    to_hash.inspect
  end
  
  private
  
  def __set(key, *args, &block)
    key = key.to_s
    value = block || args.shift
    options = args.extract_options!
    
    __settings[key] = QConfig::Setting.new(value, options)
  end
  
  def __get(key)
    key = key.to_s
    if __settings.include?(key)
      result = __settings[key]
      Setting === result ? result.value : result
    else
      raise ArgumentError, "#{key.inspect} not found in #{__settings.keys.inspect}"
    end
  end
  
  def __settings
    @__settings ||= {}
  end
  
  def __sources
    @__sources ||= []
  end
  
  def __parse_file(file)
    __parse_string(File.read(file))
  end
  
  def __parse_string(string)
    eval(string)
  end
end
