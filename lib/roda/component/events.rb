class Roda
  class Component
    class Events < Struct.new(:klass, :component_opts, :scope, :request)
      def on name, options = {}, form_klass = false, extra_opts = false, &block
        options = '' if options.empty? && (name.to_s == 'history_change' || name.to_s == 'ready')

        if client? && options.is_a?(String)
          class_name   = klass._name
          class_events = (events[class_name] ||= {})
          event        = (class_events[:_jquery_events] ||= [])
          event        << [block, class_name, options, form_klass, extra_opts, name]
        elsif options.is_a?(Hash)
          limit_if = options.delete(:if) || []
          limit_if = [limit_if] unless limit_if.is_a? Array

          class_name   = options.delete(:for) || klass._name
          class_events = (events[class_name] ||= {})
          event        = (class_events[name.to_s] ||= [])

          # remove the type, if we have an on if and it isn't in the engine_type
          if limit_if.any? && !limit_if.include?(engine_type.to_sym)
            block = Proc.new {}
          end

          event << [block, klass._name, options]
        end
      end

      def trigger_jquery_events
        return unless e = events[klass._name]

        vip_list = ['history_change']

        j_events = (e[:_jquery_events] || [])
        j_events = j_events.sort_by do |x|
          [vip_list.index(x.last.to_s) || vip_list.length, j_events.index(x)]
        end

        j_events.each do |event|
          block, comp, selector, form_klass, opts, name = event

          opts = {} unless opts

          name = name.to_s

          case name.to_s
          when 'ready'
            el = Element.find(selector != '' ? selector : 'body')

            Component::Instance.new(component(comp), scope).instance_exec el, &block
          when 'history_change'
            $window.history.change do |he|
              Component::Instance.new(component(comp), scope).instance_exec he, &block
            end
          when 'form'
            warn 'missing form class option' unless form_klass

            Document.on :submit, selector do |evt|
              el = evt.current_target
              evt.prevent_default

              params = {}

              # loop through all the forum values
              el.serialize_array.each do |row|
                field, _ = row

                # we need to make it native to access it like ruby
                field    = Native(field)
                name     = field['name']
                value    = field['value']

                params[name] = value
              end

              params_obj = {}

              params.each do |param, value|
                keys = param.gsub(/[^a-z0-9_]/, '|').gsub(/\|\|/, '|').gsub(/\|$/, '').split('|')
                params_obj = params_obj.deep_merge keys.reverse.inject(value) { |a, n| { n => a } }
              end

              opts[:dom] = el

              if opts && key = opts[:key]
                form = form_klass.new params_obj[key], opts
              else
                form = form_klass.new params_obj, opts
              end

              el.find(opts[:error_selector] || '.field-error').remove

              Component::Instance.new(component(comp), scope).instance_exec form, evt.current_target, evt, &block
            end
          else
            Document.on name, selector do |evt|
              el = evt.current_target
              Component::Instance.new(component(comp), scope).instance_exec el, evt, &block
            end
          end
        end
      end

      def trigger name, options = {}
        content = ''
        e = events[klass._name]

        return unless e

        (e[name.to_s] || []).each do |event|
          block, comp, opts = event

          if !opts[:socket]
            response = Component::Instance.new(component(comp), scope).instance_exec options, &block

            if response.is_a? Roda::Component::DOM
              content = response.to_xml
            else
              content = response
            end
          else
            $faye.publish("/components/#{klass._name}", {
              name: klass._name,
              type: 'event',
              event_type: 'call',
              event_method: name.to_s,
              data: options
            }) if $faye
          end
        end

        content
      end

      private

      def component comp
        if server?
          Object.const_get(component_opts[:class_name][comp][:class]).new scope
        else
          component_opts[:comp][comp][:class]
        end
      end

      def events
        component_opts[:events]
      end

      def engine_type
        RUBY_ENGINE == 'ruby' ? 'server' : 'client'
      end

      def server?
        RUBY_ENGINE == 'ruby' ? true : false
      end
      alias :server :server?

      def client?
        !server?
      end
      alias :client :client?
    end
  end
end
