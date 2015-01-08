class LoginComponent < Roda::Component
  name :login
  html "../public/chat/login.html"
  setup do |dom|
    dom.at('body')['class'] = 'login'
  end

  def display
    return unless server?

    component(:layout, body_class: 'login') do
      dom.find('body').html
    end
  end
end
