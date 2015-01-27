class Roda
  class Component
    class DOM
      attr_accessor :dom, :raw_html

      def initialize html
        @raw_html = html

        if server?
          @dom = raw_html.is_a?(String) ? Component::HTML(raw_html.dup): raw_html
        else
          @dom = raw_html.is_a?(String) ? Element[raw_html.dup] : raw_html
        end
      end

      def find string, &block
        if server?
          node = DOM.new dom.css(string)
        else
          node = DOM.new dom.find(string)
        end

        if block
          node.each do |n|
            block.call DOM.new n
          end
        else
          if server?
            node = DOM.new node.first
          end
        end

        node
      end

      unless RUBY_ENGINE == 'opal'
        def data key = false, value = false
          d = Hash[node.xpath("@*[starts-with(name(), 'data-')]").map{|a| [a.name, a.value]}]

          if !key
            d
          elsif key && !value
            d[key]
          else
            node["data-#{key}"] = value
          end
        end
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
