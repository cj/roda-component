class Roda
  class Component
    class Events < Struct.new(:klass, :component_opts, :scope)
      def on name, options = {}, &block
        if !options.is_a? String
          limit_if = options.delete(:if) || []
          limit_if = [limit_if] unless limit_if.is_a? Array

          class_name   = options.delete(:for) || klass._name
          class_events = (events[class_name] ||= {})
          event        = (class_events[name.to_s] ||= [])

          # remove the type, if we have an on if and it isn't in the engine_type
          if limit_if.any? && !limit_if.include?(engine_type.to_sym)
            block = Proc.new {}
          end
          event << [block, klass._name, options]
        elsif client?
          class_name   = klass._name
          class_events = (events[class_name] ||= {})
          event        = (class_events[:_jquery_events] ||= [])
          event        << [block, class_name, options, name]
        end
      end

      def trigger_jquery_events
        return unless e = events[klass._name]

        e[:_jquery_events].each do |event|
          block, comp, selector, name = event

          name = name.to_s

          if name != 'ready'
            Document.on name, selector do |evt|
              Component::Instance.new(component(comp), scope).instance_exec evt.current_target, evt, &block
            end
          else
            Component::Instance.new(component(comp), scope).instance_exec Document.find(selector), nil, &block
          end
        end
      end

      def trigger name, options = {}
        content = ''

        events[klass._name][name.to_s].each do |event|
          block, comp, _ = event

          response = Component::Instance.new(component(comp), scope).instance_exec options, &block

          if response.is_a? Roda::Component::DOM
            content = response.to_xml
          elsif response.is_a? String
            content = response
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

      def engine_type
        RUBY_ENGINE == 'ruby' ? 'server' : 'client'
      end

      def server?
        RUBY_ENGINE == 'ruby' ? 'server' : false
      end
      alias :server :server?

      def client?
        RUBY_ENGINE == 'opal' ? 'client' : false
      end
      alias :client :client?
    end
  end
end
