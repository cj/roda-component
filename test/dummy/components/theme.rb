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

  def test
    puts 'testing'
  end

  # add message to chat box
  on :ready, '.box-footer button' do |el|
    chat_box = el.closest('.box').find('#chat-box')
    footer   = chat_box.closest('.box').find('.box-footer')
    input    = footer.find('input')

    footer.find('button').on 'click' do
      test
      row = tmpl(:chat_box_row)
      chat_box.append row.dom

      puts input.val
    end
  end
end
