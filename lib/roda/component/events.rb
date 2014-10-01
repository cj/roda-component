class Roda
  class Component
    class Events < Struct.new(:klass, :component_opts, :scope)
      def on name, options = {}, &block
        class_name   = options.delete(:for) || klass._name
        class_events = (events[class_name] ||= {})
        event        = (class_events[name] ||= [])
        event << [block, klass._name, options]
      end

      def trigger name, options = {}
        content = ''

        events[klass._name][name].each do |event|
          block, comp, _ = event

          response = Instance.new(component(comp), scope).instance_exec options, &block

          if response.is_a? Roda::Component::DOM
            content = response.to_html
          elsif response.is_a? String
            content = response.to_s
          end
        end

        content
      end

      private

      def component comp
        if server?
          Object.const_get(component_opts[:class_name][comp]).new scope
        else
          component_opts[:comp][comp]
        end
      end

      def events
        component_opts[:events]
      end

      def server?
        RUBY_ENGINE == 'ruby'
      end
      alias :server :server?

      def client?
        RUBY_ENGINE == 'opal'
      end
      alias :client :client?

      class Instance < Struct.new(:instance, :scope)
        def method_missing method, *args, &block
          if instance.respond_to? method, true
            instance.send method, *args, &block
          elsif server && scope.respond_to?(method, true)
            scope.send method, *args, &block
          else
            super
          end
        end

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
  end
end
