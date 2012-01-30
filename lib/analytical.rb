require File.dirname(__FILE__)+'/analytical/rails/engine'
require File.dirname(__FILE__)+'/analytical/modules/base'
Dir.glob(File.dirname(__FILE__)+'/analytical/**/*.rb').each do |f|
  require f
end

module Analytical
  
  def analytical(options={})
    self.analytical_config = Analytical::Configuration.new(options)
  end
  
  module InstanceMethods
    def analytical
      @analytical ||= begin
        options = self.class.analytical_config.options.merge({
          :ssl => request.ssl?,
          :controller => self,
        })
        if options[:disable_if] && options[:disable_if].call(self)
          options[:modules] = []
        end
        options[:session] = session if options[:use_session_store]
        if analytical_is_robot?(request.user_agent)
          options[:modules] = []
        end
        options[:modules] = options[:filter_modules].call(self, options[:modules]) if options[:filter_modules]
        options[:javascript_helpers] ||= true if options[:javascript_helpers].nil?
        Analytical::Api.new options
      end
    end
  end

  module HelperMethods
    def analytical
      controller.analytical
    end
  end

end

if defined?(ActionController::Base)
  ActionController::Base.class_eval do
    extend Analytical
    include Analytical::InstanceMethods
    include Analytical::BotDetector
    helper Analytical::HelperMethods

    if ::Rails::VERSION::MAJOR < 3
      class_inheritable_accessor :analytical_config
    else
      class_attribute :analytical_config
    end
  end
end
