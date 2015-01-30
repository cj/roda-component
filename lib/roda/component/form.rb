require 'roda/component/form/validations'

class Roda
  class Component
    class Form
      include Validations

      class Attributes
        def set_values(atts)
          @_attributes = []

          atts.each do |key, val|
            if respond_to?("#{key}=")
              send(:"#{key}=", val)
              @_attributes << key
            end
          end
        end

        def set_attr_accessors attrs
          attrs.each do |attr|
            define_singleton_method "#{attr}=" do |value|
              value = value.to_obj if value.is_a? Hash
              instance_variable_set(:"@#{attr}", value)
            end

            define_singleton_method attr do
              instance_variable_get(:"@#{attr}")
            end
          end
        end

        def _attributes
          @_attributes ||= []
        end

        def empty?
          _attributes.empty?
        end
      end

      # Initialize with a hash of attributes and values.
      # If extra attributes are sent, a NoMethodError exception will be raised.
      #
      # @example
      #
      #   class EditPost < Scrivener
      #     attr_accessor :title
      #     attr_accessor :body
      #
      #     def validate
      #       assert_present :title
      #       assert_present :body
      #     end
      #   end
      #
      #   edit = EditPost.new(title: "Software Tools")
      #
      #   edit.valid? #=> false
      #
      #   edit.errors[:title] #=> []
      #   edit.errors[:body]  #=> [:not_present]
      #
      #   edit.body = "Recommended reading..."
      #
      #   edit.valid? #=> true
      #
      #   # Now it's safe to initialize the model.
      #   post = Post.new(edit.attributes)
      #   post.save
      def initialize(atts, options = {})
        @_data    = atts
        @_data    = atts.to_obj if atts.is_a? Hash
        @_options = options

        # @_attributes = Class.new(Attributes).new
        @_attributes = Attributes.new
        @_attributes.set_attr_accessors _attr_accessors
        @_attributes.set_values _data

        _form.each do |key, klass|
          opts = {}
          opts[key] = _data.send(key) if _data.respond_to?(key)
          @_attributes.set_values opts
        end
      end

      def self.attr_accessor(*vars)
        @_attr_accessors ||= []
        @_form ||= {}

        vars.each do |v|
          if !v.is_a? Hash
            @_attr_accessors << v unless @_attr_accessors.include? v
          else
            v = v.first

            unless @_attr_accessors.include? v.first
              @_attr_accessors << v.first
              @_form[v.first] = v.last
            end
          end
        end
      end

      def method_missing method, *args, &block
        # respond_to?(symbol, include_all=false)
        if _attributes.respond_to? method, true
          _attributes.send method, *args, &block
        else
          super
        end
      end

      # Return hash of attributes and values.
      def attributes
        Hash.new.tap do |atts|
          _attributes.instance_variables.each do |ivar|
            # todo: figure out why it's setting @constructor and @toString
            next if ivar == :@constructor || ivar == :@toString || ivar == :@_attributes || ivar == :@_data || ivar == :@_forms

            att = ivar[1..-1].to_sym
            atts[att] = _attributes.send(att)
          end
        end
      end

      def model_attributes data = attributes
        hash = {}

        data.each do |k, v|
          if klass = _form[k.to_s.to_sym]
            data = data[k]

            f = klass.new data
            k = "#{k}_attributes"
            data = f.attributes

            hash[k] = model_attributes data
          elsif v.is_a? Hash
            hash[k] = model_attributes data[k]
          else
            hash[k] = v
          end
        end

        hash
      end

      def slice(*keys)
        Hash.new.tap do |atts|
          keys.each do |att|
            atts[att] = _attributes.send(att)
          end
        end
      end

      def display_errors options = {}
        dom = options.delete(:dom) || _dom
        d_errors = errors

        if override_errors = options[:override_errors]
          d_errors = override_errors
        end

        keys = options.delete(:keys) || (_options[:key] ? [_options[:key]] : [])

        if extra_errors = options.delete(:errors)
          extra_errors.each do |key, value|
            d_errors[key] = value
          end
        end

        d_errors.each do |key, error|
          d_keys = (keys.dup << key)

          error = error.first

          if error.is_a?(Hash)
            d_options = options.dup
            d_options[:keys] = d_keys
            d_options[:override_errors] = d_errors[key].first

            display_errors d_options
          else
            name = d_keys.each_with_index.map do |field, i|
              i != 0 ? "[#{field}]" : field
            end.join

            if tmpl = options[:tmpl]
              if client?
                field_error_dom = DOM.new(`#{tmpl.dom}[0].outerHTML`)
              else
                field_error_dom = DOM.new(tmpl.dom.to_html)
              end
            else
              field_error_dom = DOM.new('<span class="field-error"><span>')
            end

            field_error_dom.html _error_name(key, error)

            field = dom.find("[name='#{name}']")
            field.before field_error_dom.dom
          end
        end
      end
      alias_method :render_errors, :display_errors

      def render_values dom = false, key = false, data = false
        dom = _options[:dom] unless dom
        key = _options[:key] if !key && _options.key?(:key)

        dom.find('input, select, textarea') do |element|
          name  = element['name']
          name  = name.gsub(/\A#{key}/, '') if key
          keys  = name.gsub(/\A\[/, '').gsub(/[^a-z0-9_]/, '|').gsub(/\|\|/, '|').gsub(/\|$/, '').split('|')
          value = false

          keys.each do |k|
            begin
              value = value ? value.send(k) : send(k)

              if klass = _form[k.to_s.to_sym]
                options = {}
                options[:key] = _options[:key] if _options.key? :key

                value = klass.new(value, options)
              end
            rescue
              value = ''
            end
          end

          case element.name
          when 'select'
            element.find('option') do |x|
              x['selected'] = true if x['value'] == value.to_s
            end
          when 'input'
            element['value'] = value.to_s
          when 'textarea'
            element.val value.to_s
          end
        end
      end

      protected

      def self._attr_accessors
        @_attr_accessors
      end

      def self._form
        @_form
      end

      def _attributes
        @_attributes ||= []
      end

      def _form
        self.class._form
      end

      def _data
        @_data ||= []
      end

      def _attr_accessors
        self.class._attr_accessors
      end

      def _options
        @_options
      end

      def _dom
        @_dom ||= @_options[:dom]
      end

      def _error_name key, error
        case error.to_s.to_sym
        when :not_email
          'Email Isn\'t Valid.'
        when :not_present
          'Required.'
        when :not_equal
          'Password does not match.'
        else
          error
        end
      end

      def empty?
        _attributes.empty?
      end

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
