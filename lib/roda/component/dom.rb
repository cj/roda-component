require 'opal-jquery'

unless RUBY_ENGINE == 'opal'
  require 'nokogiri'
end

class Roda
  class Component < Struct.new(:scope)
    class DOM
      attr_accessor :dom

      def initialize html
        if server?
          @dom = Nokogiri::HTML html
        else
          @dom = Element
        end
      end

      def find string, &block
        if server?
          @node = dom.at string
        else
          @node = dom.find string
        end

        if block
          block.call @node
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

      def html
        @node.to_html
      end

      private

      def server? &block
        RUBY_ENGINE == 'ruby'
      end

      def client?
        RUBY_ENGINE == 'opal'
      end
    end
  end
end
