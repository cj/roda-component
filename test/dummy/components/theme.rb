class BoxComponent < Roda::Component
  name :theme
  html "../public/AdminLTE-master/index.html"

  setup do |dom|
    # remove sales box
    dom.at('#revenue-chart').xpath('//div[contains(@class,"nav-tabs-custom")]').first['style'] = 'display: none;'
    # dom.css('script[src*=morris]').remove

    # set chat box and grab chatbox row
    box      = dom.find('#chat-box').ancestors('.box').first
    chat_box = dom.at('#chat-box')
    tmpl :chat_box_row, box.css('.item').first
    chat_box.css('.item').remove
    box.at('box-tools').remove
  end

  def display data, &block
    component(:layout) do
      dom.find('body').html
    end if server?
  end

  # add message to chat box
  on :ready, '.box-footer button' do |el|
    box = el.closest('.box').find('#chat-box').closest('.box')

    box.find('.box-footer button').on('click') { add_chat_row_to box }
    box.find('.box-footer input').on('keydown') do |evt|
      # on enter add chat row
      if evt.which == 13
        add_chat_row_to box
      end
    end
  end

  private

  def add_chat_row_to box
    chat_box = box.find('#chat-box')
    input    = box.find('.box-footer input')
    value    = input.val
    row      = tmpl(:chat_box_row)

    if value.length > 0
      # we don't need attachments
      row.find('.attachment').remove
      row.find('.message').html = value
      input.prop 'value', ''

      chat_box.append row.dom
      # make sure we always scroll to the bottom
      chat_box.scroll_top(chat_box.height + 99999)
    else
      # error message: input can't be blank
    end
  end
end
