require 'opal'
require 'faye'

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
          # load component
          component = Object.const_get(
            component_opts[:cache][:component][name.to_sym]
          ).new self

          # call action
          response = component.send(options[:call] || 'default', &block)
          response.to_s
        end
      end

      module ClassMethods
        # Copy the assets options into the subclass, duping
        # them as necessary to prevent changes in the subclass
        # affecting the parent class.
        def inherited(subclass)
          super
          opts         = subclass.opts[:component] = component_opts.dup
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
          Regexp.new(component_opts[:route] + '/(.*)(|\/.*)')
        end
      end

      module RequestMethods
        def components
          on self.class.component_route_regex do |component, action|
            scope.component(component, call: !action.empty?? action : 'default')
          end
        end
      end
    end

    register_plugin(:component, Component)
  end
end
