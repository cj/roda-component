require 'opal'
require 'opal-jquery'

unless RUBY_ENGINE == 'opal'
  require 'tilt'

  if defined? Oga
    require 'roda/component/oga'
  end
end

require "base64"
require 'roda/component/faye'
require 'roda/component/instance'
require 'roda/component/dom'
require 'roda/component/events'

if RUBY_ENGINE == 'opal'
  class Element
    alias_native :val
    alias_native :serialize_array, :serializeArray
  end

  $component_opts ||= {
    events: {},
    comp: {},
    cache: {},
    tmpl: {}
  }
end

class Roda
  class Component
    attr_accessor :scope, :cache

    def initialize(scope = false)
      @scope   = scope

      if client?
        $faye.subscribe "/components/#{self.class._name}" do |msg|
          msg = Native(msg)

          trigger :"#{msg[:type]}", msg['local'], msg unless $faye.public_id == msg[:public_id]
        end

        $faye.on 'transport:up' do
          $faye.online = true

          if $faye.disconnected
            trigger :reconnect
          else
            trigger :connect
          end
        end

        $faye.on 'transport:down' do
          $faye.disconnected = true
          $faye.online       = false
          trigger :disconnect
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
        if server?
          yield
        else
          m = Module.new(&block)

          m.public_instance_methods(false).each do |meth|
            define_method "#{meth}" do |*args, &blk|
              name     = self.class._name
              # event_id = "comp-event-#{$faye.generate_id}"

              HTTP.post("/components/#{name}/call/#{meth}",
                headers: {
                  'X-CSRF-TOKEN' => Element.find('meta[name=_csrf]').attr('content'),
                  'X-RODA-COMPONENT-ON-SERVER' => true
                },
                payload: args.first) do |response|

                  # We set the new csrf token
                  xhr  = Native(response.xhr)
                  csrf = xhr.getResponseHeader('NEW-CSRF')
                  Element.find('meta[name=_csrf]').attr 'content', csrf
                  ###########################

                  blk.call Native(response.body), response
              end

              # Element['body'].on event_id do |event, local, data|
              #   blk.call local, event, data
              # end
              #
              # $faye.publish("/components/outgoing/#{$faye.private_id}/#{$faye.public_id}", {
              #   name: name,
              #   type: 'event',
              #   event_type: 'call',
              #   event_method: meth,
              #   event_id: event_id,
              #   local: args.first || nil
              # })


              true
            end
          end

          include m
        end
      end

      # The name of the component
      alias_method :name_original, :name
      def comp_name(_name = nil)
        return name_original unless _name

        @_name = _name.to_s

        if server?
          component_opts[:class_name][@_name] = self.to_s
        end
      end

      # The html source
      def comp_html _html, &block
        if server?
          if _html.is_a? String
            if _html[%r{\A./}]
              cache[:html] = File.read _html
            else
              cache[:html] = File.read "#{component_opts[:path]}/#{_html}"
            end
          else
            cache[:html] = yield
          end

          cache[:dom] = DOM.new(cache[:html])
        end
      end

      def HTML raw_html
        if raw_html[/\A<!DOCTYPE/] || raw_html[/\A<html/]
          Nokogiri::HTML(raw_html)
        else
          parsed_html = Nokogiri::HTML.fragment(raw_html)

          if parsed_html.children.length == 1
            parsed_html.children.first
          else
            parsed_html
          end
        end
      end

      # setup your dom
      def comp_setup &block
        block.call cache[:dom] if server?
      end

      def events
        @_events ||= Events.new self, component_opts, false
      end

      def on *args, &block
        if args.first.to_s != 'server'
          events.on(*args, &block)
        else
          on_server(&block)
        end
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

      # We need to save the oga dom and the raw html.
      # the reason we ave the raw html is so that we can use it client side.
      def tmpl name, dom, remove = true
        cache[:tmpl][name] = { dom: remove ? dom.remove : dom }
        cache[:tmpl][name][:html] = cache[:tmpl][name][:dom].to_html
        cache[:tmpl][name]
      end
      alias :add_tmpl :tmpl
      alias :set_tmpl :tmpl

      # shortcut to comp opts
      def component_opts
        if client?
          $component_opts
        else
          super
        end
      end

      def method_missing method, *args, &block
        if server? && app.respond_to?(method, true)
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

    def events
      @_events ||= Events.new self.class, component_opts, scope
    end

    def dom
      if server?
        # TODO: duplicate cache[:dom] so we don't need to parse all the html again
        @_dom ||= DOM.new(cache[:dom].dom.to_html)
      else
        @_dom ||= DOM.new(Element)
      end
    end
    alias_method :element, :dom

    # Grab the template from the cache, use the nokogiri dom or create a
    # jquery element for server side
    # issue: can't use the cached dom because duping doesn't work.
    def tmpl name
      if t = cache[:tmpl][name]
        DOM.new t[:html]
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
      if server? && scope.respond_to?(method, true)
        scope.send method, *args, &block
      else
        super
      end
    end

    private

    def server?
      RUBY_ENGINE == 'ruby'
    end
    alias_method :server, :server?

    def client?
      RUBY_ENGINE == 'opal'
    end
    alias_method :client, :client?
  end

  # This is just here to make things more cross compatible
  if RUBY_ENGINE == 'opal'
    RodaCache = Hash
  end
end
