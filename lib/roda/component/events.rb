unless RUBY_ENGINE == 'ruby'
  require 'native'
end

class Roda
  class Component
    class Events < Struct.new(:klass, :cache)
      def on name, options = {}, &block
        if client?
          # puts klass.cache
          # window = Native(`window`)
          # puts window.screenX
          # `console.log(#{klass}._alloc.name);`
        end
        # puts klass.new.moo
        class_events = (cache[:events][klass._name] ||= {})
        event = (class_events[name] ||= [])
        event << [block, options]
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
  end
end
