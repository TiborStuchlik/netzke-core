require 'active_support/core_ext'
require 'netzke/core/ruby_ext'
require 'netzke/core/client_code'
require 'netzke/core/stylesheets'
require 'netzke/core/services'
require 'netzke/core/composition'
require 'netzke/core/plugins'
require 'netzke/core/configuration'
require 'netzke/core/state'
require 'netzke/core/embedding'
require 'netzke/core/actions'
require 'netzke/core/session'
require 'netzke/core/core_i18n'
require 'netzke/core/inheritance'
require 'netzke/core/support'
require 'netzke/core/authorization'

module Netzke
  # The base class for every Netzke component. Its main responsibilities include:
  # * Client class generation and inheritance (using Ext JS class system) which reflects the Ruby class inheritance (see {Netzke::Core::ClientCode})
  # * Nesting and dynamic loading of child components (see {Netzke::Core::Composition})
  # * Ruby-side action declaration (see {Netzke::Actions})
  # * I18n
  # * Client-server communication (see {Netzke::Core::Services})
  # * Session-based persistence (see {Netzke::Core::State})
  #
  # Client-side methods are documented [here](http://api.netzke.org/client/classes/Netzke.Base.html).
  #
  # == Referring to JavaScript configuration methods from Ruby
  #
  # Netzke allows use Ruby symbols for referring to pre-defined pieces of configuration. Let's say for example, that a toolbar needs to nest a control more complex than a button (say, a date field), and a component should still make it possible to make it's presence and position in the toolbar configurable. We can implement it like this:
  #
  #     action :do_something
  #
  #     def configure(c)
  #       super
  #       c.tbar = [:do_something, :date_selector]
  #     end
  #
  # While :do_something here is referring to a usual Netzke action, :date_selector is not declared in actions. If our JavaScript include file contains a method called `dateSelectorConfig`, it will be executed at the moment of configuring `tbar` at client side, and it's result, a config object, will substitute `date_selector`:
  #
  #     {
  #       dateSelectorConfig: function(config){
  #         return {
  #           xtype: 'datefield'
  #         }
  #       }
  #     }
  #
  # This doesn't necessarily have to be used in toolbars, but also in other places in config (i.e. layouts).
  class Base
    include Core::Session
    include Core::State
    include Core::Configuration
    include Core::Authorization
    include Core::ClientCode
    include Core::Services
    include Core::Composition
    include Core::Plugins
    include Core::Stylesheets
    include Core::Embedding
    include Core::Actions
    include Core::CoreI18n
    include Core::Inheritance

    # These are set during initialization
    mattr_accessor :session, :controller, :logger

    attr_reader :parent, :name, :item_id, :path

    # Instantiates a component instance. A parent can optionally be provided.
    def initialize(conf = {}, parent = nil)
      @passed_config = conf

      # parent component
      @parent = parent

      # name fo the component used in the +component+ DSL block, and is a part of component's +@path+
      @name = conf[:name] || self.class.name.underscore

      # path down the composition hierarchy (composed of names)
      @path = parent.nil? ? @name : "#{parent.path}__#{@name}"

      # JS id in the scope of the parent component. Auto-generated when using multiple instance loading.
      # Full JS id will be built using these along the +@path+
      @item_id = conf[:item_id] || @name

      # Make +client_config+ accessible in +configure+ before calling +super+
      client_config = Netzke::Support.permit_hash_params(conf.delete(:client_config))
      config.client_config = HashWithIndifferentAccess.new(client_config)

      # by tiba
      #li ">>>>   INITIALIZE: #{@path}"

      config.iconCls = 'tyb-header-icon'

      #config.title = tu self.class.to_s

      @dbconf = Component.get(self)
      #config.merge! @dbconf.config
      code, res = evalute
      if code == 0
        if res.is_a? Hash
          config.merge! res
        end
        config.evalute_result = :ok
      else
        config.evalute_result = :error
      end

      config.merge! @dbconf.virtual_config

      #end by tiba

      # Build complete component configuration
      configure(config)

      config.merge! @dbconf.post_config

      # Check whether the config is valid (as specified in a custom override)
      validate_config(config)

      if (session[:devel])
      end

      if session[:settings]
        if (config.is_setting)
          config.header = {
              style: {
                background: 'rgba(255,0,0,0.3)'
              }
          }
        end
        config.tools ||= []
        config.tools <<
            {
                type: :gear,
                scope: f("this"),
                callback: f("settings")
            }
        self.class.settings_component
      else
        if (config.is_setting)
          config.header = false
        end
      end

      normalize_config

      config.deep_freeze
    end

    def dbconf
      @dbconf
    end

    def evalute
      code = @dbconf.config
      begin
        [0, eval(code, binding)]
      rescue => err
        [1, err]
      end
    end

    private

    def self.settings_component
      component :settings do |c|
        c.klass = System::Settings
      end
    end

  end
end
