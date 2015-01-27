require 'tilt'
require 'faye'
require 'faye/redis'
require 'roda/component'
require 'roda/component/faye'
require 'json'
require "base64"

class Roda
  module RodaPlugins
    module Component
      def self.load_dependencies(app, opts={})
        Faye::WebSocket.load_adapter('thin')
      end

      def self.configure(app, opts={})
        if app.opts[:component]
          app.opts[:component].merge!(opts)
        else
          app.opts[:component] = opts.dup
        end

        opts                     = app.opts[:component]
        opts[:cache]             = app.thread_safe_cache if opts.fetch(:cache, true)
        opts[:path]            ||= 'components'
        opts[:route]           ||= 'components'
        opts[:debug]           ||= false
        opts[:assets_route]    ||= 'assets/components'
        opts[:class]           ||= Roda::Component
        opts[:settings]        ||= {}
        opts[:class_name]      ||= {}
        opts[:events]          ||= {}
        opts[:user_model]      ||= 'User'
        opts[:redis_uri]       ||= 'redis://localhost:6379'
        opts[:redis_namespace] ||= 'roda:component:'
        opts[:cache][:tmpl]    ||= {}

        app.use(Faye::RackAdapter, {
          mount: '/faye',
          extensions: [
            Roda::Component::Faye::CsrfProtection.new,
            Roda::Component::Faye::ChannelManager.new
          ],
          engine: {
            type:      Faye::Redis,
            uri:       opts[:redis_uri],
            namespace: opts[:redis_namespace]
          }
        })

        # Roda::Component::Ohm.redis = Redic.new opts[:redis_uri] || 'redis://localhost:6379'

        # Set the current app
        opts[:class].set_app app
      end

      module InstanceMethods
        def component_opts
          @_component_opts || self.class.component_opts.dup
        end

        def loaded_component_js
          request.env['loaded_component_js'] ||= []
        end

        def load_component name
          Object.const_get(
            component_opts[:class_name][name.to_s]
          ).new self
        end

        def load_component_js comp, action = :display, options = {}
          # grab a copy of the cache
          cache = comp.class.cache.dup
          # remove html and dom cache as we don't need that for the client
          cache.delete :html
          cache.delete :dom
          cache.delete :cache

          cache     = Base64.encode64 cache.to_json
          options   = Base64.encode64 options.to_json
          comp_name = comp.class._name

          js = <<-EOF
            unless $faye
              $faye = Roda::Component::Faye.new('/faye')
            end

            unless $component_opts[:comp][:"#{comp_name}"]
              Document.ready? do
                c = $component_opts[:comp][:"#{comp_name}"] = #{comp.class}.new
                c.instance_variable_set(:@_cache, JSON.parse(Base64.decode64('#{cache}')))
                c.events.trigger_jquery_events
                c.#{action}(JSON.parse(Base64.decode64('#{options}')))
              end
            end
          EOF

          loaded_component_js << ("<script>#{Opal.compile(js)}</script>")

          file_path = comp.class.instance_methods(false).map { |m|
              comp.class.instance_method(m).source_location.first
          }.uniq.first.gsub("#{Dir.pwd}/#{component_opts[:path]}", '').gsub(/\.rb\Z/, '.js')

          loaded_component_js << "<script type=\"text/javascript\" src=\"/#{component_opts[:assets_route]}#{file_path}\"></script>"
        end

        def component name, options = {}, &block
          comp = load_component name

          action  = options.delete(:call)    || :display
          trigger = options.delete(:trigger) || false
          js      = options.delete(:js)
          args    = options.delete(:args)

          # call action
          # TODO: make sure the single method parameter isn't a block
          if trigger
            if args
              comp_response = comp.trigger trigger, *args
            else
              comp_response = comp.trigger trigger, options
            end
          else
            # We want to make sure it's not a method that already exists in ruba
            # otherwise that would give us a false positive.
            if comp.respond_to?(action) && !"#{comp.method(action)}"[/\(Kernel\)/]
              if comp.method(action).parameters.length > 0
                if args
                  comp_response = comp.send(action, *args, &block)
                else
                  comp_response = comp.send(action, options, &block)
                end
              else
                comp_response = comp.send(action, &block)
              end
            else
              fail "##{action} doesn't exist for #{comp.class}"
            end
          end

          load_component_js comp, action, options

          if js && comp_response.is_a?(Roda::Component::DOM)
            comp_response = comp_response.to_xml
          end

          if comp_response.is_a?(String) && js
            comp_response << component_js
          end

          comp_response
        end
        alias :comp :component
        alias :roda_component :component

        def component_js
          loaded_component_js.join(' ').to_s
        end
      end

      module ClassMethods
        # Copy the assets options into the subclass, duping
        # them as necessary to prevent changes in the subclass
        # affecting the parent class.
        def inherited(subclass)
          super
          opts         = component_opts.dup
          opts[:cache] = thread_safe_cache if opts[:cache]
        end

        def component_opts
          opts[:component]
        end
      end

      module RequestClassMethods
        def component_opts
          roda_class.component_opts
        end

        def component_assets_route_regex
          component_opts[:assets_route]
        end

        def component_route_regex
          Regexp.new(
            component_opts[:route] + "/([a-zA-Z0-9_-]*)/([a-zA-Z0-9_-]*)/([a-zA-Z0-9_-]*)"
          )
        end
      end

      module RequestMethods
        def components
          opal = Opal::Server.new do |s|
            # Append the gems path
            if scope.component_opts[:debug]
              s.debug = true
              s.source_map = true
            else
              s.source_map = false
            end

            s.append_path Gem::Specification.find_by_name("roda-component").gem_dir + '/lib'

            # Append the path to the components folder
            s.append_path scope.component_opts[:path]

            s.main = 'roda/component'
          end

          on self.class.component_assets_route_regex do |component, action|
            path = scope.request.env['REQUEST_PATH']

            if path[/\.js\Z/]
              run opal.sprockets
            elsif scope.component_opts[:debug]
              if path[/\.rb\Z/] && js_file = scope.request.env['PATH_INFO'].scan(/(.*\.map)/)
                scope.request.env['PATH_INFO'] = path.gsub(js_file.last.first, '').gsub("/#{scope.component_opts[:assets_route]}", '')
              end

              run Opal::SourceMapServer.new(opal.sprockets, path)
            end
          end

          on self.class.component_route_regex do |comp, type, action|
            if scope.request.env.include? 'HTTP_X_RODA_COMPONENT_ON_SERVER'
              data = JSON.parse scope.request.body.read
            else
              data = {}
            end

            if data.is_a? Array
              data = {args: data}
            end

            case type
            when 'call'
              data[:call] = action
            when 'trigger'
              data[:trigger] = action
            end

            res = scope.roda_component(comp, data)

            scope.response.headers["NEW-CSRF"] = scope.csrf_token

            if res.is_a? Hash
              scope.response.headers["Content-Type"] = 'application/json; charset=UTF-8'
              res = res.to_json
            else
              res = res.to_s
            end

            res
          end
        end
      end
    end

    register_plugin(:component, Component)
  end
end
