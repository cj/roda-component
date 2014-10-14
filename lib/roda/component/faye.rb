if RUBY_ENGINE == 'opal'
  require 'native'

  class Roda
    class Component
      class Faye
        include Native

        alias_native :subscribe
        alias_native :unsubscribe
        alias_native :publish
        alias_native :bind
        alias_native :cancel
        alias_native :on
        alias_native :then
        alias_native :set_header, :setHeader
        alias_native :add_extension, :addExtension

        def initialize url
          super `new Faye.Client(#{url})`
          set_header 'X-CSRF-TOKEN', Element.find('meta[name=_csrf]').attr('content')
          add_extension({
            incoming: ->(message, block) { incoming message, block },
            outgoing: ->(message, block) { outgoing message, block }
          })
        end

        def public_id
          @public_id ||= generate_id
        end

        def private_id
          @private_id ||= generate_id
        end

        def incoming message, block
          msg = Native(message)

          if (!@public_id && !@private_id) && msg[:channel] == '/meta/handshake'
            subscribe "/components/incoming/#{private_id}/#{public_id}" do |data|
              data     = Native(data)
              event_id = data[:event_id]
              body     = Element['body']

              body.trigger(event_id, data[:local], data)
              body.off event_id
            end
          end

          block.call message
        end

        def outgoing message, block
          message = %x{
            message = #{message}
            message.ext = message.ext || {};
            message.ext.csrfToken = $('meta[name=_csrf]').attr('content');
          }
          block.call message
        end

        private

        def generate_id
          o = [('a'..'z'), ('A'..'Z'), (0..9)].map { |i| i.to_a }.flatten
          (0...50).map { o[rand(o.length)] }.join
        end
      end
    end
  end
else
  require 'faye'
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
            app = get_app(request)

            if data = message['data']
              case data['type']
              when 'event'
                options = { local: data['local'] }
                data['event_type'] == 'call' \
                  ? options[:call] = data['event_method'] \
                  : options[:trigger] = data['event_method']

                message['data']['local'] = app.roda_component(:"#{data['name']}", options)
                message['channel']       = message['channel'].gsub(/outgoing/, 'incoming')
              end
            end

            callback.call message
          end

          # /components/:id/:comp/:action
          # def outgoing(message, request, callback)
          #   app = get_app request
          #
          #   # message[:data] = app.roda_component(:auth, call: :cow) || false
          #
          #   ap '====OUTGOING===='
          #   ap message
          #   ap '================'
          #
          #   callback.call message
          # end

          def get_app request
            request.env['RODA_COMPONENT_FROM_FAYE'] = true
            a = Class.new(Roda::Component.app.class).new
            a.instance_variable_set(:@_request, request)
            a
          end
        end
      end
    end
  end
end
