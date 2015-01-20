require 'roda/component/form/validations'

class Roda
  class Component
    class Form
      include Validations

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

        atts.each do |key, val|
          send(:"#{key}=", val)
        end
      end

      # Return hash of attributes and values.
      def attributes
        Hash.new.tap do |atts|
          instance_variables.each do |ivar|
            # todo: figure out why it's setting @constructor and @toString
            next if ivar == :@errors || ivar == :@_options || ivar == :@_dom  || ivar == :@constructor || ivar == :@toString

            att = ivar[1..-1].to_sym
            atts[att] = send(att)
          end
        end
      end

      def slice(*keys)
        Hash.new.tap do |atts|
          keys.each do |att|
            atts[att] = send(att)
          end
        end
      end

      def display_errors options = {}
        if extra_errors = options.delete(:errors)
          extra_errors.each do |key, value|
            errors[key] = value
          end
        end

        errors.each do |key, error|
          error = error.first
          field_error_dom = options.delete :tmpl
          field_error_dom = DOM.new('<span class="field-error"><span>') unless field_error_dom
          field_error_dom.html _error_name(key, error)

          field = _dom.find("input[name='#{key}']")
          field.before field_error_dom.dom
        end
      end

      protected

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
