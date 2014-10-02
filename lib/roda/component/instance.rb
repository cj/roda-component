class Roda
  class Component
    class Instance
      attr_accessor :instance, :scope

      def initialize instance, scope = false
        @instance = instance
        @scope    = scope
      end

      # this is a hack because it seems like display is a ruby object method
      # when doing method(:display) it gives #<Method: # Roda::Component::Instance(Kernel)#display>
      def display *args
        method_missing(*args)
      end

      def method_missing method = 'display', *args, &block
        if instance.respond_to? method, true
          instance.send method, *args, &block
        elsif server && scope && scope.respond_to?(method, true)
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
