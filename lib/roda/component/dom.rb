unless RUBY_ENGINE == 'opal'
  require 'nokogiri'
end

class Roda
  class Component < Struct.new(:scope)
    class DOM
      attr_accessor :dom

      def initialize dom
        @dom = dom
      end

      def find string, &block
        if server?
          @node = dom.css string
        else
          @node = dom.find string
        end

        if block
          if server?
            @node.each do |node|
              block.call node
            end
          else
            block.call @node
          end
        else
          if server?
            block.call @node.first
          else
            block.call @node
          end
        end

        self
      end

      def html= content
        if server?
          @node.inner_html = content
        else
          @node.html content
        end

        self
      end

      def html content = false
        if !content
          if server?
            @node ? @node.to_html : dom.to_html
          else
            @node ? @node.html : dom.html
          end
        else
          self.html = content
        end
      end

      # This allows you to use all the nokogiri or opal jquery methods if a
      # global one isn't set
      def method_missing method, *args, &block
        # respond_to?(symbol, include_all=false)
        if dom.respond_to? method, true
          dom.send method, *args, &block
        else
          super
        end
      end

      private

      def server? &block
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
