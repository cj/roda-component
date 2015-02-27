class Roda
  class Component
    class Form
      # Provides a base implementation for extensible validation routines.
      # {Scrivener::Validations} currently only provides the following assertions:
      #
      # * assert
      # * assert_present
      # * assert_format
      # * assert_numeric
      # * assert_url
      # * assert_email
      # * assert_member
      # * assert_length
      # * assert_decimal
      # * assert_equal
      #
      # The core tenets that Scrivener::Validations advocates can be summed up in a
      # few bullet points:
      #
      # 1. Validations are much simpler and better done using composition rather
      #    than macros.
      # 2. Error messages should be kept separate and possibly in the view or
      #    presenter layer.
      # 3. It should be easy to write your own validation routine.
      #
      # Other validations are simply added on a per-model or per-project basis.
      #
      # @example
      #
      #   class Quote
      #     attr_accessor :title
      #     attr_accessor :price
      #     attr_accessor :date
      #
      #     def validate
      #       assert_present :title
      #       assert_numeric :price
      #       assert_format  :date, /\A[\d]{4}-[\d]{1,2}-[\d]{1,2}\z
      #     end
      #   end
      #
      #   s = Quote.new
      #   s.valid?
      #   # => false
      #
      #   s.errors
      #   # => { :title => [:not_present],
      #          :price => [:not_numeric],
      #          :date  => [:format] }
      #
      module Validations
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

        # Check if the current model state is valid. Each call to {#valid?} will
        # reset the {#errors} array.
        #
        # All validations should be declared in a `validate` method.
        #
        # @example
        #
        #   class Login
        #     attr_accessor :username
        #     attr_accessor :password
        #
        #     def validate
        #       assert_present :user
        #       assert_present :password
        #     end
        #   end
        #
        def valid?
          errors.clear
          validate
          errors.empty?
        end

        # Base validate implementation. Override this method in subclasses.
        def validate
        end

        # Hash of errors for each attribute in this model.
        def errors
          @errors ||= Hash.new { |hash, key| hash[key] = [] }
        end

        protected

        # Allows you to do a validation check against a regular expression.
        # It's important to note that this internally calls {#assert_present},
        # therefore you need not structure your regular expression to check
        # for a non-empty value.
        #
        # @param [Symbol] att The attribute you want to verify the format of.
        # @param [Regexp] format The regular expression with which to compare
        #                 the value of att with.
        # @param [Array<Symbol, Symbol>] error The error that should be returned
        #                                when the validation fails.
        def assert_format(att, format, error = [att, :format])
          if assert_present(att, error)
            assert(_attributes.send(att).to_s.match(format), error)
          end
        end

        # The most basic and highly useful assertion. Simply checks if the
        # value of the attribute is empty.
        #
        # @param [Symbol] att The attribute you wish to verify the presence of.
        # @param [Array<Symbol, Symbol>] error The error that should be returned
        #                                when the validation fails.
        def assert_present(att, error = [att, :not_present])
          if att.is_a? Array
            att.each { |a| assert_present(a, error = [a, :not_present])}
          else
            if klass = _form[att]
              options = {}
              options[:key] = _options[:key] if _options.key? :key

              f = klass.new(_attributes.send(att).attributes, options)
              assert(f.valid?, [att, f.errors])
            else
              assert(!_attributes.send(att).to_s.empty?, error)
            end
          end
        end

        # Checks if all the characters of an attribute is a digit.
        #
        # @param [Symbol] att The attribute you wish to verify the numeric format.
        # @param [Array<Symbol, Symbol>] error The error that should be returned
        #                                when the validation fails.
        def assert_numeric(att, error = [att, :not_numeric])
          if assert_present(att, error)
            if client?
              assert_format(att, /^\-?\d+$/, error)
            else
              assert_format(att, /\A\-?\d+\z/, error)
            end
          end
        end

        if client?
          URL = /^(http|https):\/\/([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}|(2 5[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3} |localhost)(:[0-9]{1,5})?(\/.*)?$/i
        else
          URL = /\A(http|https):\/\/([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}|(2 5[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3} |localhost)(:[0-9]{1,5})?(\/.*)?\z/i
        end

        def assert_url(att, error = [att, :not_url])
          if assert_present(att, error)
            assert_format(att, URL, error)
          end
        end

        if client?
          EMAIL = /^[a-z0-9!\#$%&'*\/=\?^{|}+_-]+(?:\.[a-z0-9!\#$%&'*\/=\?^{|}+_-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/i
        else
          EMAIL = /\A[a-z0-9!\#$%&'*\/=\?^{|}+_-]+(?:\.[a-z0-9!\#$%&'*\/=\?^{|}+_-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/i
        end

        def assert_email(att, error = [att, :not_email])
          if assert_present(att, error)
            assert_format(att, EMAIL, error)
          end
        end

        def assert_member(att, set, err = [att, :not_valid])
          assert(set.include?(_attributes.send(att)), err)
        end

        def assert_length(att, range, error = [att, :not_in_range])
          if assert_present(att, error)
            val = _attributes.send(att).to_s
            assert range.include?(val.length), error
          end
        end

        if client?
          DECIMAL = /^\-?(\d+)?(\.\d+)?$/
        else
          DECIMAL = /\A\-?(\d+)?(\.\d+)?\z/
        end

        def assert_decimal(att, error = [att, :not_decimal])
          assert_format att, DECIMAL, error
        end

        # Check that the attribute has the expected value. It uses === for
        # comparison, so type checks are possible too. Note that in order
        # to make the case equality work, the check inverts the order of
        # the arguments: `assert_equal :foo, Bar` is translated to the
        # expression `Bar === send(:foo)`.
        #
        # @example
        #
        #   def validate
        #     assert_equal :status, "pending"
        #     assert_equal :quantity, Fixnum
        #   end
        #
        # @param [Symbol] att The attribute you wish to verify for equality.
        # @param [Object] value The value you want to test against.
        # @param [Array<Symbol, Symbol>] error The error that should be returned
        #                                when the validation fails.
        def assert_equal(att, value, error = [att, :not_equal])
          assert value === _attributes.send(att), error
        end

        # The grand daddy of all assertions. If you want to build custom
        # assertions, or even quick and dirty ones, you can simply use this method.
        #
        # @example
        #
        #   class CreatePost
        #     attr_accessor :slug
        #     attr_accessor :votes
        #
        #     def validate
        #       assert_slug :slug
        #       assert votes.to_i > 0, [:votes, :not_valid]
        #     end
        #
        #   protected
        #     def assert_slug(att, error = [att, :not_slug])
        #       assert send(att).to_s =~ /\A[a-z\-0-9]+\z/, error
        #     end
        #   end
        def assert(value, error)
          value or errors[error.first].push(error.last) && false
        end
      end
    end
  end
end
