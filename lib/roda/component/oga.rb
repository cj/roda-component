require 'oga'

module Oga
  module XML
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
    end
  end
end
