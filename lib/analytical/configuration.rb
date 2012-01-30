module Analytical

  class Configuration

    attr_accessor :options
    
    def initialize(options = {})
      @options = options.reverse_merge load_from_file config_filename
    end

    def [](key)
      @options[key]
    end
    
    private

    def config_filename
      File.join(::Rails.root, "config/analytical.yml")
    end
    
    def load_from_file(filename)
      config_options = { :modules => [] }
      File.open(filename) do |f|
        file_options = YAML::load(ERB.new(f.read).result).symbolize_keys
        env = (::Rails.env || :production).to_sym
        file_options = file_options[env] if file_options.has_key?(env)
        file_options.each do |k, v|
          if v.respond_to?(:symbolize_keys)
            # module configuration
            config_options[k.to_sym] = v.symbolize_keys
            config_options[:modules] << k.to_sym unless options && options[:modules]
          else
            # regular option
            config_options[k.to_sym] = v
          end
        end if file_options
      end if File.exists?(filename)
      config_options
    end
    
  end

end
