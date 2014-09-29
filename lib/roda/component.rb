require 'opal'
require 'roda/component/dom'

class Roda
  class Component
    VERSION = "0.0.1"

    class << self
      if RUBY_ENGINE == 'ruby'
        def inherited(subclass)
          super
          # We want to set the app for all sub classes
          subclass.set_app app
        end
      end

      # The name of the component
      def name _name
        if server?
          component_cache[:component][_name] = self.to_s
        end

        @_name = _name
      end

      # The html source
      def html _html, &block
        if server?
          if _html.is_a? String
            cache[:html] = File.read _html
          else
            cache[:html] = yield
          end
        end
      end

      # cache for class
      def cache
        if server?
          @_cache ||= Roda::RodaCache.new
        else
          @_cache ||= {
            dom: false
          }
        end
      end

      # set the current roda app
      def set_app app
        @_app = app
      end

      # roda app method
      def app
        @_app ||= {}
      end

      # shortcut to comp opts
      def component_opts
        if server?
          app.component_opts
        else
          {}
        end
      end

      # shortcut to component_cache
      def component_cache
        if server?
          app.component_opts[:cache]
        else
          @_cache ||= {
            component: {}
          }
        end
      end

      private

      def server?
        RUBY_ENGINE == 'ruby'
      end

      def client?
        RUBY_ENGINE == 'opal'
      end
    end

    def cache
      @_cache ||= self.class.cache.dup
    end

    def dom
      @_dom ||= DOM.new cache[:html]
    end

    private

    def server?
      RUBY_ENGINE == 'ruby'
    end
    alias :server :server?

    def client?
      RUBY_ENGINE == 'opal'
    end
    alias :client :client?
  end
end
