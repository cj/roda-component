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

        attr_accessor :disconnect

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
          # puts '====INCOMING===='
          # `console.log(#{message})`
          # puts '================'

          if (!@public_id && !@private_id) && message[:channel] == '/meta/handshake'
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
            message.ext.public_id = #{public_id};
            message.ext.private_id = #{private_id};
          }

          # puts '====OUTGOING===='
          # `console.log(#{message})`
          # puts '================'

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
  require 'redic'
  # require 'roda/component/ohm'
  # require 'roda/component/models/user'
  # require 'roda/component/models/channel'

  class Roda
    class Component
      class Faye
        class CsrfProtection
          def incoming(message, request, callback)
            case message['channel']
            when '/meta/connect', '/meta/handshake', '/meta/subscribe', '/meta/disconnect', '/meta/unsubscribe'
              session_token = request.session['csrf.token']
              message_token = message['ext'] && message['ext'].delete('csrfToken')

              unless session_token == message_token
                message['error'] = '401::Access denied'
              end
            else
              app_token     = Roda::Component.app.component_opts[:token]
              message_token = message['data'] && message['data'].delete('token')


              unless app_token == message_token
                message['error'] = '401::Access denied'
              end
            end

            callback.call(message)
          end
        end

        class ChannelManager
          def redis
            @redis ||= Redic.new(Roda::Component.app.component_opts[:redis_uri])
          end

          def incoming(message, request, callback)
            app = get_app(request)

            public_id  = message['ext'] && message['ext']['public_id']
            private_id = message['ext'] && message['ext'].delete('private_id')

            # app.session['roda_component'] ||= {
            #   'public_ids' => {}
            # }

            case message['channel']
            when '/meta/connect'
              if public_id.length > 0
                redis.call 'SET', "#{app.component_opts[:redis_namespace]}users:#{public_id}", private_id
              end
              callback.call message
            when '/meta/disconnect'
              redis.call 'DEL', "#{app.component_opts[:redis_namespace]}users:#{public_id}"
              callback.call message
            when '/meta/unsubscribe'
              puts 'unsubscribe'
            when '/meta/subscribe'
              if message['subscription'][%r{\A/components/}]
                component_name = message['subscription'].split('/').last

                callback.call message

                app.roda_component(:"#{component_name}", { trigger: :join, public_id: public_id, private_id: private_id })

                client = ::Faye::Client.new("#{request.env['HTTP_ORIGIN']}/faye")
                client.set_header 'X-CSRF-TOKEN', message['ext']['csrfToken']
                client.publish "/components/#{component_name}", type: 'join', public_id: message['ext']['public_id'], token: app.component_opts[:token]
              end
            else
              if data = message['data']
                case data['type']
                when 'event'
                  options = { local: data['local'] }
                  data['event_type'] == 'call' \
                    ? options[:call]    = data['event_method'] \
                    : options[:trigger] = data['event_method']

                  message['data']['local'] = app.roda_component(:"#{data['name']}", options)
                  message['channel']       = message['channel'].gsub(/outgoing/, 'incoming')
                end
              end

              callback.call message
            end
          end

          # /components/:id/:comp/:action
          def outgoing(message, request, callback)
            app = get_app request

            # message[:data] = app.roda_component(:auth, call: :cow) || false

            # ap '====OUTGOING===='
            # ap message
            # ap '================'

            callback.call message
          end

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
