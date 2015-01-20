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

        attr_accessor :disconnected, :online

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

          def incoming(message, r, callback)
            r.env['RODA_COMPONENT_FROM_FAYE'] = true
            r.env['HTTP_X_RODA_COMPONENT_ON_SERVER'] = true

            app = get_app(r)

            session_id = r.session['session_id']
            public_id  = message['ext'] && message['ext']['public_id']
            private_id = message['ext'] && message['ext'].delete('private_id')
            key        = "#{app.component_opts[:redis_namespace]}users:#{session_id}"

            case message['channel']
            when '/meta/connect'
              if session_id
                redis.call 'HSET', "#{key}/ids", private_id, public_id
                # puts redis.call 'HGETALL', "#{key}/ids"
              end
              callback.call message
            when '/meta/disconnect'
              callback.call message

              redis.call 'DEL', "#{key}/ids"
              channels = redis.call 'GET', "#{key}/channels/#{public_id}"
              channels = channels ? JSON.parse(channels) : []

              channels.each do |channel|
                send_sub_to({
                  'channel'      => '/meta/unsubscribe',
                  'subscription' => channel,
                  'ext'          => message['ext']
                }, public_id, private_id, app, key, r)
              end

              redis.call 'DEL', "#{key}/channels/#{public_id}"
            when '/meta/subscribe', '/meta/unsubscribe'
              if message['subscription'][%r{\A/components/}]
                callback.call message
                send_sub_to message, public_id, private_id, app, key, r
              end
            else
              if data = message['data']
                case data['type']
                when 'event'
                  options ||= {}
                  options.merge! data['local']

                  data['event_type'] == 'call' \
                    ? options[:call]    = data['event_method'] \
                    : options[:trigger] = data['event_method']

                  begin
                    message['data']['local'] = app.roda_component(:"#{data['name']}", options)
                    message['channel']       = message['channel'].gsub(/outgoing/, 'incoming')
                  rescue Exception => e
                    #fix: faye extentions are capturing errors for some reason
                    ap e.message
                    ap e.message.inspect
                  end
                end
              end

              callback.call message
            end
          end

          def send_sub_to message, public_id, private_id, app, key, request
            key = "#{key}/channels/#{public_id}"

            joining = message['channel'] == '/meta/subscribe' ? true : false

            component_name = message['subscription'].split('/').last

            channels = redis.call 'GET', key
            channels = channels ? JSON.parse(channels) : []

            if joining
              channels << message['subscription']
            else
              channels.delete message['subscription']
            end

            if channels.length
              redis.call 'SET', key, channels.to_json
            end

            data = app.roda_component(:"#{component_name}", { trigger: (joining ? :join : :leave), public_id: public_id, private_id: private_id })

            url = "http#{request.env['SERVER_PORT'] == '443' ? 's' : ''}://#{request.env['SERVER_NAME']}:#{request.env['SERVER_PORT']}/faye"
            client = ::Faye::Client.new(url)
            client.publish "/components/#{component_name}", type: (joining ? 'join' : 'leave'), public_id: public_id, token: app.component_opts[:token], local: data
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
