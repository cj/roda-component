class BoxComponent < Roda::Component
  name :theme
  html "../public/AdminLTE-master/index.html"

  # setup do |dom|
  #   tmpl :about_title, dom.at_css('#about h2.about-title')
  # end

  setup do |dom|
    # remove sales box
    dom.at('#revenue-chart').xpath('//div[contains(@class,"nav-tabs-custom")]').first['style'] = 'display: none;'
    # dom.css('script[src*=morris]').remove

    # set chat box and grab chatbox row
    chat_box = dom.at('#chat-box')
    tmpl :chat_box_row, chat_box.css('.item').first
    chat_box.css('.item').remove
  end

  def display data, &block
    component(:layout) do
      dom.find('body').html
    end if server?
  end

  # add message to chat box
  on :ready, '.box-footer button' do |el|
    chat_box = el.closest('.box').find('#chat-box')
    box      = chat_box.closest('.box')

    box.find('.box-footer button').on('click') { add_chat_row_to box }
    box.find('.box-footer input').on('keydown') do |evt|
      if evt.which == 13
        add_chat_row_to box
      end
    end
  end

  private

  def add_chat_row_to box
    chat_box = box.find('#chat-box')
    input    = box.find('.box-footer input')

    row = tmpl(:chat_box_row)
    # we don't need attachments
    row.find('.attachment').remove
    row.find('.message').html = input.val
    input.prop 'value', ''

    chat_box.append row.dom
    chat_box.scroll_top(chat_box.height + 2000)
  end
end
