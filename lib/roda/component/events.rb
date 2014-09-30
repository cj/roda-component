class Roda
  class Component
    class Events < Struct.new(:klass, :component_opts, :scope)
      def on name, options = {}, &block
        class_events = (events[klass._name] ||= {})
        event = (class_events[name] ||= [])
        event << [block, options]
      end

      def trigger name, options = {}
        events[klass._name][name].each do |event|
          block, options = event
          Instance.new(component).instance_exec options, &block
        end
      end

      private

      def component
        if server?
          Object.const_get(component_opts[:class_name][klass._name]).new scope
        else
          component_opts[:comp][klass._name]
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
          elsif scope && scope.respond_to?(method, true)
            scope.send method, *args, &block
          else
            super
          end
        end
      end
    end
  end
end
