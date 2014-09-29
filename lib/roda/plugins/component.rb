require 'roda/component'
require 'json'

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
        opts[:class]             ||= Roda::Component
        opts[:settings]          ||= {}
        opts[:cache][:component] ||= {}

        # Set the current app
        opts[:class].set_app app

        # Load all components
        Dir[opts[:path] + '/**/*.rb'].each { |file| require file }
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

          js = <<-EOF
            Document.ready? do
              #{component.class}.new.#{action}(JSON.parse('#{options.to_json}'))
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
          'assets/components'
        end
      end

      module RequestMethods
        def components
          on self.class.component_route_regex do |component, action|
            # scope.component(component, call: !action.empty?? action : 'display')
            Opal::Processor.source_map_enabled = false
            env = Opal::Environment.new
            env.append_path Gem::Specification.find_by_name("roda-component").gem_dir + '/lib'
            js = env['roda/component'].to_s

            env.append_path scope.component_opts[:path]

            Dir[scope.component_opts[:path] + '/**/*.rb'].each do |file|
              file = file.gsub(scope.component_opts[:path] + '/', '')
              js << env[file].to_s
            end

            response.headers["Content-Type"] = 'application/javascript; charset=UTF-8'

            js
          end
        end
      end
    end

    register_plugin(:component, Component)
  end
end
