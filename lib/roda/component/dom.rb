require 'delegate'

class Roda
  class Component
    class DOM < SimpleDelegator
      attr_accessor :dom, :raw_html

      def initialize html
        @raw_html = html.dup

        if server?
          @dom = Component::HTML(raw_html)
        else
          @dom = raw_html.is_a?(String) ? Element[raw_html] : raw_html
        end

        super dom
      end

      def find string, &block
        if server?
          @node = dom.css string
        else
          @node = dom.find string
        end

        if block
          if server?
            node.each do |n|
              block.call n
            end
          else
            block.call node
          end
        else
          if server?
            @node = node.first
          end
        end

        node
      end

      def html= content
        if server?
          node.inner_html = content
        else
          node.html content
        end

        node
      end

      def html content = false
        if !content
          if server?
            node.inner_html
          else
            node ? node.html : dom.html
          end
        else
          self.html = content
        end
      end

      def node
        @node || dom
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
