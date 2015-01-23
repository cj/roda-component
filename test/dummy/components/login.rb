require_relative 'forms/login'

class LoginComponent < Roda::Component
  comp_name :login
  comp_html "../public/chat/login.html"
  comp_setup do |dom|
    tmpl :field_error, dom.at('.field-error')
    dom.css('.signup, .forgot-password, .remember-me').remove
  end

  def display
    return unless server?

    session['display'] = 'login'

    component(:layout, body_class: 'login') do
      dom.find('body').html
    end
  end

  def logout
    super(TestApp::Models::User)
    request.redirect 'login'
  end

  on :server do
    def login_with params
      signup = params.delete('signup')
      form   = Forms::Login.new params

      if signup
        if form.valid?
          TestApp::Models::User.create form.slice(:first_name, :last_name, :email, :password)
          login(TestApp::Models::User, form.email, form.password)
          {success: true}
        else
          {success: false, errors: form.errors}
        end
      else
        user = TestApp::Models::User.where(email: form.email).first

        return {success: false, reason: 'Account doesn\'t exist.'} unless user

        if login(TestApp::Models::User, form.email, form.password)
          {success: true}
        else
          {success: false, errors: { email: ['Email and Password combination is incorrect.']}}
        end
      end
    end
  end

  on :form, 'form.main-form', Forms::Login do |form, el, evt|
    if form.valid?
      login_with form.attributes do |res|
        if res['success']
          # redirect them to the chatroom
          `window.location.replace("/")`
        else
          case res['reason']
          when /doesn't exist/
            # Add fields for them to signup with
            container = el.find('.field-container')
            container.prepend('<input name="signup" type="hidden" value=true>')
            container.prepend('<input name="last_name" type="text" placeholder="Last Name">')
            container.prepend('<input name="first_name" type="text" placeholder="First Name">')
            container.find("[name='password']").after('<input name="password_confirmation" type="password" placeholder="Confirm Password">')
          else
            # Show server errors
            form.display_errors tmpl: tmpl(:field_error), errors: res['errors']
          end
        end
      end
    else
      form.display_errors tmpl: tmpl(:field_error)
    end
  end
end
