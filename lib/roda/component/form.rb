require 'roda/component/form/validations'

class Roda
  class Component
    class Form
      include Validations

      class Attributes
        def set_values(atts)
          atts.each do |key, val|
            send(:"#{key}=", val)
          end
        end

        def set_attr_accessors attrs
          attrs.each do |attr|
            define_singleton_method "#{attr}=" do |value|
              instance_variable_set(:"@#{attr}", value)
            end

            define_singleton_method attr do
              instance_variable_get(:"@#{attr}")
            end
          end
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
        @_options = options

        # @_attributes = Class.new(Attributes).new
        @_attributes = Attributes.new
        @_attributes.set_attr_accessors _attr_accessors
        @_attributes.set_values atts
      end

      def self.attr_accessor(*vars)
        @_attr_accessors ||= []
        @_attr_accessors.concat vars
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
            next if ivar == :@constructor || ivar == :@toString

            att = ivar[1..-1].to_sym
            atts[att] = _attributes.send(att)
          end
        end
      end

      def slice(*keys)
        Hash.new.tap do |atts|
          keys.each do |att|
            atts[att] = _attributes.send(att)
          end
        end
      end

      def display_errors options = {}
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

          if error.is_a? Hash
            d_options = options.dup
            d_options[:keys] = d_keys
            d_options[:override_errors] = d_errors[key].first

            display_errors d_options
          else
            name = d_keys.each_with_index.map do |field, i|
              i != 0 ? "[#{field}]" : field
            end.join

            field_error_dom = options.delete :tmpl
            field_error_dom = DOM.new('<span class="field-error"><span>') unless field_error_dom
            field_error_dom.html _error_name(key, error)

            field = _dom.find("input[name='#{name}']")
            field.before field_error_dom.dom
          end
        end
      end
      alias_method :render_errors, :display_errors

      def render_values dom = false, key = false, data = false
        dom = _options[:dom] unless dom
        key = _options[:key] if !key && _options.key?(:key)
        data = attributes unless data

        data.each do |k, v|
          k = "#{key}[#{k}]" if !key.nil?
          if v.is_a?(Hash)
            render_values dom, k, v
          else
            dom.find('input, select') do |element|
              if element['name'] == k
                case element.name
                when 'select'
                  element.find('option').each do |x|
                    x['selected'] = true if x['value']==v.to_s
                  end
                when 'input'
                  element['value'] = v.to_s
                end
              end
            end
          end
        end
      end

      protected

      def self._attr_accessors
        @_attr_accessors
      end

      def _attributes
        @_attributes ||= []
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
        case error.to_sym
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
    end
  end
end
