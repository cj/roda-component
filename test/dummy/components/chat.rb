class ChatComponent < Roda::Component
  name :chat
  html "../public/chat/index.html"

  def display
    if server?
      component(:layout) do
        dom.find('body').html
      end
    end
  end

  on :reconnect do
    puts 'reconnected'
  end

  on :disconnect do
    puts 'disconnected'
  end

  on :connect do
    puts 'connected'
  end

  on :join do |data|
    if client?
      puts 'joined'
    else
      ap session
      puts 'joined server'
    end
  end

  on :leave do |data|
    puts 'left'
    false
  end
end
