require 'oga'

module Oga
  module XML
    module Querying
      alias_method :at, :at_css
    end

    class Element < Node
      def inner_html
        html = ''

        children.each do |node|
          html << node.to_xml
        end

        return html
      end

      def inner_html=(html)
        @children = HTML::Parser.new(html).parse.children
      end

      def add_child html
        HTML::Parser.new(html).parse.children.each do |node|
          @children << node
        end
      end
    end

    class Document
      def to_s
        to_xml
      end
    end
  end
end
