module Netzke
  module Core
    class JavascriptClassConfig
      attr_accessor :included_files, :base_class, :properties

      def initialize
        @included_files = []
        @base_class = "Ext.panel.Panel"
        @properties = {}
      end

      def base_class base_class
        @base_class = base_class
      end

      def property name, value
        @properties[name.to_sym] = value
      end

      # Use it to specify JS files to be loaded before this component's JS code. Useful when using external extensions required by this component.
      # It may accept one or more symbols or strings. Strings will be interpreted as full paths to included JS file:
      #
      #     js_include "#{File.dirname(__FILE__)}/my_component/one.js","#{File.dirname(__FILE__)}/my_component/two.js"
      #
      # Symbols will be expanded following a convention, e.g.:
      #
      #     class MyComponent < Netzke::Base
      #       js_include :some_library
      #       # ...
      #     end
      #
      # This will "include" a JavaScript file +{component_location}/my_component/javascripts/some_library.js+
      def include(*args)
        callr = caller.first

        @included_files |= args.map{ |a| a.is_a?(Symbol) ? expand_js_include_path(a, callr) : a }
      end

    private

      def expand_js_include_path(sym, callr) # :nodoc:
        %Q(#{callr.split(".rb:").first}/javascripts/#{sym}.js)
      end

    end
  end
end