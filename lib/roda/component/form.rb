require 'roda/component/form/validations'
require 'forwardable'

class Roda
  class Component
    class Form
      include Validations

      module Delegates
        def _delegates(*names)
          accessors = Module.new do
            extend Forwardable # DISCUSS: do we really need Forwardable here?
            names.each do |name|
              delegate [name, "#{name}="] => :_attributes
            end
          end
          include accessors
        end
      end

      extend Delegates

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
              @_attributes ||= []
              @_attributes << attr
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

        _data.each do |key, val|
          send("#{key}=", val)
        end

        _form.each do |key, klass|
          opts = {}
          opts[key] = klass.new(_data.send(key)) if _data.respond_to?(key)
          @_attributes.set_values opts

          send("#{key}=", opts[key])
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

        _delegates(*_attr_accessors)
      end

      def method_missing method, *args, &block
        # respond_to?(symbol, include_all=false)
        if _data.respond_to? method, true
          _data.send method, *args, &block
        else
          return if method[/\=\z/]

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

            if klass = _form[att.to_s.to_sym]
              atts[att] = klass.new(atts[att]).attributes
            end
          end
        end
      end

      def model_attributes data = attributes
        hash = {}

        data.each do |k, v|
          if klass = _form[k.to_s.to_sym]
            d = data[k]
            d = d.attributes if d.is_a?(Form)

            f  = klass.new d
            k  = "#{k}_attributes"
            dt = f.model_attributes

            hash[k] = model_attributes dt
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
            atts[att] = send(att)
            # atts[att] = _attributes.send(att)
          end
        end
      end

      def display_errors options = {}, &block
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

            display_errors d_options, &block
          elsif block_given?
            block.call(d_keys, error)
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
            if element['type']=='radio'
              if element['value'] == value.to_s
                element['checked'] = true
              else
                element.delete 'checked'
              end
            else
              value = sprintf('%.2f', value) if value.is_a? BigDecimal
              element['value'] = value.to_s
            end
          when 'textarea'
            element.val value.to_s
          end
        end
      end

      def _attributes
        @_attributes ||= {}
      end

      def validate_msg error, column
        false
      end

      protected

      def _data
        @_data ||= {}
      end

      def self._attr_accessors
        @_attr_accessors ||= []
      end

      def self._form
        @_form || {}
      end

      def _form
        self.class._form
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
        validate_msg(error.to_sym, key.to_sym) || case error.to_s.to_sym
        when :not_email
          'Email Isn\'t Valid.'
        when :not_present
          'Required.'
        when :not_equal
          'Password does not match.'
        else
          !error[/\s/] ? error.to_s.gsub(/_/, ' ').titleize : error
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

      def self.server? &block
        RUBY_ENGINE == 'ruby'
      end
      alias :server :server?

      def self.client?
        RUBY_ENGINE == 'opal'
      end
      alias :client :client?
    end
  end
end
