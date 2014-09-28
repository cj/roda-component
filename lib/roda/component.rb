require 'opal'
require 'roda/component/dom'

class Roda
  class Component
    VERSION = "0.0.1"

    class << self
      def inherited(subclass)
        super
        # We want to set the app for all sub classes
        subclass.set_app app
      end

      # The name of the component
      def name _name
        component_cache[:component][_name] = self.to_s
        @_name = _name
      end

      # The html source
      def html _html, &block
        if _html.is_a? String
          cache[:html] = File.read _html
        else
          cache[:html] = yield
        end
      end

      # cache for class
      def cache
        @_cache ||= Roda::RodaCache.new
      end

      # set the current roda app
      def set_app app
        @_app = app
      end

      # roda app method
      def app
        @_app
      end

      # shortcut to comp opts
      def component_opts
        app.component_opts
      end

      # shortcut to component_cache
      def component_cache
        app.component_opts[:cache]
      end
    end

    def cache
      @_cache ||= self.class.cache.dup
    end

    def dom
      cache[:dom] ||= DOM.new cache[:html]
    end
  end
end
