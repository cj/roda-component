class ChatComponent < Roda::Component
  comp_name :chat
  comp_html "../public/chat/index.html"

  def display
    return unless server?

    request.redirect 'login' unless current_user

    dom.find('.my-account .name span').html current_user.full_name

    component(:layout) do
      dom.find('body').html
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
    return user_details unless client?

    `console.log(#{data});`
    puts 'joined'
  end

  on :leave do |data|
    return user_details unless client?

    `console.log(#{data});`
    puts 'leave'
  end

  def user_details
    {
      id: current_user.id,
      first_name: current_user.first_name,
      last_name: current_user.last_name
    }
  end
end
