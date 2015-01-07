class ChatComponent < Roda::Component
  name :chat
  html "../public/chat/index.html"

  def display
    component(:layout) do
      dom.find('body').html
    end if server?
  end

  on :join do
    puts 'joined'
  end
end
