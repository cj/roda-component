unless RUBY_ENGINE == 'opal'
  require 'nokogiri'
end

class Roda
  class Component < Struct.new(:scope)
    class DOM
      attr_accessor :dom

      def initialize html
        @dom = Nokogiri::HTML html
      end

      def find string
        @node = dom.at string

        self
      end

      def html= content
        @node.inner_html = content

        self
      end

      def to_s
        @dom.to_s
      end
    end
  end
end
