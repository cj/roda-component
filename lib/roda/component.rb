require 'opal'
require 'opal-jquery'
require "base64"
require 'roda/component/dom'
require 'roda/component/events'

if RUBY_ENGINE == 'opal'
  $component ||= {}
end

class Roda
  class Component
    VERSION = "0.0.1"

    attr_accessor :scope

    def initialize(scope = false)
      @scope = scope
    end

    class << self
      attr_accessor :_name

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

          cache[:dom] = Nokogiri::HTML cache[:html]
        end
      end

      # setup your dom
      def setup &block
        block.call cache[:dom] if server?
      end
      alias :clean :setup

      def events
        @_events ||= Events.new self, component_cache
      end

      # cache for class
      def cache
        @_cache ||= {
          tmpl: {}
        }
      end

      # set the current roda app
      def set_app app
        @_app = app.respond_to?(:new) ? app.new : app
      end

      # roda app method
      def app
        @_app ||= {}
      end

      # We need to save the nokogiri dom and the raw html.
      # the reason we ave the raw html is so that we can use it client side.
      def tmpl name, dom, remove = true
        cache[:tmpl][name] = {
          dom: remove ? dom.remove : dom
        }
        cache[:tmpl][name][:html] = cache[:tmpl][name][:dom].to_html
        cache[:tmpl][name]
      end
      alias :add_tmpl :tmpl
      alias :set_tmpl :tmpl

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
          @_comp_cache ||= {
            component: {},
            tmpl: {},
            events: {}
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

    def cache= new_cache
      @_cache = new_cache
    end

    def events
      self.class.events
    end

    def dom
      d = cache[:dom] || begin
        if server?
          Nokogiri::HTML cache[:html]
        else
          Element
        end
      end

      DOM.new d
    end

    # Grab the template from the cache, use the nokogiri dom or create a
    # jquery element for server side
    def tmpl name
      if server?
        DOM.new cache[:tmpl][name][:dom].dup
      else
        DOM.new Element[cache[:tmpl][name][:html].dup]
      end
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
