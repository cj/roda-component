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
        alias_native :set_header, :setHeader
        alias_native :add_extension, :addExtension
      end
    end
  end
else
  class Roda
    class Component
      class Faye
        class CsrfProtection
          def incoming(m, request, callback)
            # # fix due to opal and wrapping message in native like Native(message)
            message = { '_id' => m['_id']}
            message.merge! m['native']

            ap '======================'
            ap message
            ap request.session
            ap '======================'

            session_token = request.session['csrf.token']
            message_token = message['ext'] && message['ext'].delete('csrfToken')

            unless session_token == message_token
              message['error'] = '401::Access denied'
            end

            callback.call(message)
          end
          #
          # def outgoing(m, request, callback)
          #   ap '======================'
          #   ap 'outgoing'
          #   ap m
          #   ap request.session
          #   ap '======================'
          #   #
          #   # unless session_token == message_token
          #   #   message['error'] = '401::Access denied'
          #   # end
          #   callback.call(m)
          # end
        end
      end
    end
  end
end
