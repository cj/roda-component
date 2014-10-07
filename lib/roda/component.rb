unless RUBY_ENGINE == 'opal'
  require 'tilt'
  require 'awesome_print'
end

require 'opal'
require 'opal-jquery'
require "base64"
require 'roda/component/faye'
require 'roda/component/instance'
require 'roda/component/dom'
require 'roda/component/events'

if RUBY_ENGINE == 'opal'
  $component_opts ||= {
    events: {},
    comp: {},
    cache: {}
  }
end

module Overrideable
  def self.included(c)
    c.instance_methods(false).each do |m|
      m = m.to_sym
      c.class_eval %Q{
        alias #{m}_original #{m}
        def #{m}(*args, &block)
          puts "Foo"
          result = #{m}_original(*args, &block)
          puts "Bar"
          result
        end
      }
    end
  end
end

class Roda
  class Component
    attr_accessor :scope

    def initialize(scope = false)
      @scope = scope

      if client?
        $faye.subscribe "/components/#{self.class._name}" do |msg|
          `window.console.log(#{msg})`
        end
      end
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

      def on_server &block
        m = Module.new(&block)

        m.public_instance_methods(false).each do |meth|
          define_method "#{meth}" do |*args, &blk|
            if server?
              super()
            else
              name  = self.class._name

              $faye.subscribe("/components/#{name}/call/#{meth}") do |d|
                $faye.unsubscribe("/components/#{name}/call/#{meth}")
                blk.call d
              end.then do
                $faye.publish("/components/#{name}/call/#{meth}", {moo: 'cow'})
              end

              true
            end
          end
        end

        include m
      end

      # The name of the component
      def name _name
        @_name = _name.to_s

        if server?
          component_opts[:class_name][@_name] = self.to_s
        end
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
        @_events ||= Events.new self, component_opts, false
      end

      def on *args, &block
        events.on(*args, &block)
      end

      # cache for class
      def cache
        unless @_cache
          @_cache ||= Roda::RodaCache.new
          @_cache[:tmpl] = {}
          @_cache[:server_methods] = []
        end

        @_cache
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
          $component_opts
        end
      end

      def method_missing method, *args, &block
        if server && app.respond_to?(method, true)
          app.send method, *args, &block
        else
          super
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
      @_events ||= Events.new self.class, component_opts, scope
    end

    def dom
      if server?
        @_dom ||= DOM.new cache[:dom].dup || begin
          Nokogiri::HTML cache[:html]
        end
      else
        @_dom ||= DOM.new(Element)
      end
    end

    # Grab the template from the cache, use the nokogiri dom or create a
    # jquery element for server side
    def tmpl name
      if t = cache[:tmpl][name]
        if server?
          DOM.new t[:dom].dup
        else
          DOM.new Element[t[:html].dup]
        end
      else
        false
      end
    end

    def component_opts
      self.class.component_opts
    end

    def trigger *args
      events.trigger(*args)
    end

    def method_missing method, *args, &block
      if server && scope.respond_to?(method, true)
        scope.send method, *args, &block
      else
        super
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

  # This is just here to make things more cross compatible
  if RUBY_ENGINE == 'opal'
    RodaCache = Hash
  end
end
