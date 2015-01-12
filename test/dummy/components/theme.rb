# class BoxComponent < Roda::Component
#   name :theme
#   html "../public/AdminLTE-master/index.html"
#
#   setup do |dom|
#     # remove sales box
#     dom.at('#revenue-chart').xpath('//div[contains(@class,"nav-tabs-custom")]').first['style'] = 'display: none;'
#     # dom.css('script[src*=morris]').remove
#
#     ## set chat box and grab chatbox row
#     chat_box  = dom.at('#chat-box')
#     container = chat_box.ancestors('.box').first
#     # grab first fake message for our template
#     tmpl :chat_box_row, chat_box.css('.item').first
#     # remove all other fake messages
#     chat_box.css('.item').remove
#     # remove the chat box tools
#     container.at('.box-tools').remove
#   end
#
#   def display data, &block
#     component(:layout) do
#       dom.find('body').html
#     end if server?
#   end
#
#   # on :chat_row_added, socket: true do |msg|
#   #   puts 'moo'
#   #   # add_chat_row msg
#   # end
#
#   on :server do
#     def test
#       puts 'called from browser'
#       'defined on server'
#     end
#   end
#
#   # add message to chat box
#   on :ready, '.box-footer button' do |el|
#     # grab the box that contains the chat box
#     box = el.closest('.box').find('#chat-box').closest('.box')
#
#     # when the click the + button add a row
#     box.find('.box-footer button').on('click') { add_chat_row }
#     # when they hit enter on the input add a row
#     box.find('.box-footer input').on('keydown') do |evt|
#       if evt.which == 13
#         add_chat_row
#       end
#     end
#   end
#
#   private
#
#   def add_chat_row msg = false
#     box      = Element.find('#chat-box').closest('.box')
#     chat_box = box.find('#chat-box')
#     input    = box.find('.box-footer input')
#     msg      = msg ? msg : input.val
#     row      = tmpl(:chat_box_row)
#     ig       = box.find('.input-group')
#     classes  = ig['class'].split(' ')
#
#     test do |res|
#       puts "ran server method test, response: #{res}"
#     end
#
#     if msg.length > 0
#       # we don't need attachments
#       row.find('.attachment').remove
#       row.find('.message').html = msg
#
#       trigger :chat_row_added, msg
#
#       input.prop 'value', ''
#
#       chat_box.append row.dom
#       # make sure we always scroll to the bottom
#       chat_box.scroll_top `chat_box[0].scrollHeight`
#       classes.delete 'has-error'
#     else
#       # give the input group an error class
#       classes << 'has-error'
#     end
#
#     ig['class'] = classes.join ' '
#   end
# end
