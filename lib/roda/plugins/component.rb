require 'roda/component'
require 'json'
require "base64"

class Roda
  module RodaPlugins
    module Component
      def self.configure(app, opts={})
        if app.opts[:component]
          app.opts[:component].merge!(opts)
        else
          app.opts[:component] = opts.dup
        end

        opts                       = app.opts[:component]
        opts[:cache]               = app.thread_safe_cache if opts.fetch(:cache, true)
        opts[:path]              ||= 'components'
        opts[:route]             ||= 'components'
        opts[:assets_path]       ||= 'assets/components'
        opts[:class]             ||= Roda::Component
        opts[:settings]          ||= {}
        opts[:cache][:component] ||= {}
        opts[:cache][:tmpl]      ||= {}
        opts[:cache][:events]    ||= {}

        # Set the current app
        opts[:class].set_app app
      end

      module InstanceMethods
        def component_opts
          self.class.component_opts
        end

        def component name, options = {}, &block
          action = options[:call] || 'display'

          # load component
          component = Object.const_get(
            component_opts[:cache][:component][name.to_sym]
          ).new self

          # call action
          # TODO: make sure the single method parameter isn't a block
          if component.method(action).parameters.length > 0
            comp_response = component.send(action, options, &block)
          else
            comp_response = component.send(action, &block)
          end

          if comp_response.is_a? Roda::Component::DOM
            content = comp_response.html
          else
            content = comp_response.to_s
          end

          # grab a copy of the cache
          cache = component.class.cache.dup
          # remove html and dom cache as we don't need that for the client
          cache.delete :html
          cache.delete :dom

          cache   = Base64.encode64 cache.to_json
          options = Base64.encode64 options.to_json
          comp_name = component.class._name

          js = <<-EOF
            Document.ready? do
              c = $component[:"#{comp_name}"] = #{component.class}.new
              c.cache = JSON.parse Base64.decode64('#{cache}')
              c.#{action}(JSON.parse(Base64.decode64('#{options}')))
            end
          EOF

          content + ("<script>" + Opal.compile(js) + "</script>")
        end
        alias :comp :component
        alias :roda_component :component
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

        def component_route_regex
          component_opts[:assets_path]
        end
      end

      module RequestMethods
        def components
          on self.class.component_route_regex do |component, action|
            # Process the ruby code into javascript
            Opal::Processor.source_map_enabled = false
            env = Opal::Environment.new
            # Append the gems path
            env.append_path Gem::Specification.find_by_name("roda-component").gem_dir + '/lib'
            js = env['roda/component'].to_s
            # Append the path to the components folder
            env.append_path scope.component_opts[:path]
            # Loop through and and convert all the files to javascript
            Dir[scope.component_opts[:path] + '/**/*.rb'].each do |file|
              file = file.gsub(scope.component_opts[:path] + '/', '')
              js << env[file].to_s
            end
            # Set the header to javascript
            response.headers["Content-Type"] = 'application/javascript; charset=UTF-8'

            js
          end
        end
      end
    end

    register_plugin(:component, Component)
  end
end
