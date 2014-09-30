if RUBY_ENGINE == 'opal'
  $events ||= {}
end

class Roda
  class Component
    class Events < Struct.new(:klass, :cache)
      def on name, options = {}, &block
        if server?
          class_events = (cache[:events][klass._name] ||= {})
        else
          class_events = ($events[klass._name] ||= {})
        end

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
          Object.const_get(cache[:component][klass._name]).new self
        else
          $component[klass._name]
        end
      end

      def events
        if RUBY_ENGINE == 'ruby'
          cache[:events]
        else
          $events
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
