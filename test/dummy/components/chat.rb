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
      puts '========FROM CHAT=========\\'
      session['public_ids'] ||= []
      unless session['public_ids'].include? data[:public_id]
        session['public_ids'] << data[:public_id]
      end
      ap session
      puts '//========FROM CHAT========='
      puts 'joined server'
    end
  end

  on :leave do |data|
    puts 'left'
  end
end
