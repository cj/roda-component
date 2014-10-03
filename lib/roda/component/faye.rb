if RUBY_ENGINE == 'opal'
  require 'native'

  class Roda
    class Component
      class Faye
        include Native

        def initialize url
          super `new Faye.Client(#{url})`
        end

        alias_native :subscribe
        alias_native :publish
        alias_native :bind
        alias_native :on
        alias_native :set_header, :setHeader
        alias_native :add_extension, :addExtension
      end
    end
  end
else
  require 'roda/component/ohm'
  require 'roda/component/models/user'
  require 'roda/component/models/channel'

  class Roda
    class Component
      class Faye
        class CsrfProtection
          def incoming(message, request, callback)
            session_token = request.session['csrf.token']
            message_token = message['ext'] && message['ext'].delete('csrfToken')

            unless session_token == message_token
              message['error'] = '401::Access denied'
            end

            callback.call(message)
          end
        end

        class ChannelManager
          def incoming(message, request, callback)
            app = get_app request

            ap '====INCOMING===='
            ap message
            ap '================'

            callback.call message
          end

          # /components/:id/:comp/:action
          def outgoing(message, request, callback)
            app = get_app request

            ap '====OUTGOING===='
            ap message
            ap '================'

            callback.call message
          end

          def get_app request
            request.env['RODA_COMPONENT_FROM_FAYE'] = true
            a = Class.new(Roda::Component.app.class).new
            a.instance_variable_set(:@_request, request)
            a
          end
        end

        # class ChannelManager
        #   def incoming(message, request, callback)
        #     ap '====INCOMING===='
        #     ap message
        #     ap '================'
        #
        #     model = Component.component_opts[:user_model]
        #     id    = request.session[model]
        #     ap request.session
        #
        #     if id.present?
        #       @user = Models::User.find(model_id: id).first || begin
        #         Models::User.create(model_id: id)
        #       end
        #     else
        #       @user = 'nil'
        #     end
        #
        #     callback.call message
        #   end
        #
        #   def current_user
        #     @current_user ||= begin
        #       model = Component.component_opts[:user_model]
        #       model = Object.const_get(model)
        #
        #       if @user
        #         model.find @user.id
        #       else
        #         model.new first_name: 'Guest', last_name: 'User'
        #       end
        #     end
        #   end
        #
        #   def outgoing(message, request, callback)
        #     ap '====INCOMING===='
        #     ap message
        #     ap '================'
        #
        #     callback.call message
        #   end
        # end
      end
    end
  end
end
