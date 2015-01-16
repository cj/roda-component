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
    super(Models::User)
    request.redirect 'login'
  end

  on :server do
    def login_with params
      signup = params.delete('signup')
      form   = Forms::Login.new params

      if signup
        if form.valid?
          Models::User.create form.slice(:first_name, :last_name, :email, :password)
          login(Models::User, form.email, form.password)
          {success: true}
        else
          {success: false, errors: form.errors}
        end
      else
        user = Models::User.where(email: form.email).first

        return {success: false, reason: 'Account doesn\'t exist.'} unless user

        if login(Models::User, form.email, form.password)
          {success: true}
        else
          {success: false, errors: { email: ['Email and Password combination is incorrect.']}}
        end
      end
    end
  end

  on :ready, 'form.main-form' do |el|
    el.on :submit do |evt|
      evt.prevent_default

      params = {}
      el.find('.field-error').remove

      # loop through all the forum values
      el.serialize_array.each do |row|
        field, _ = row

        # we need to make it native to access it like ruby
        field    = Native(field)
        name     = field['name']
        value    = field['value']

        params[name] = value
      end

      form = Forms::Login.new params

      if form.valid?
        login_with params do |res|
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
              display_errors res['errors']
            end
          end
        end
      else
        display_errors form.errors
      end
    end
  end

  protected

  def display_errors errors
    errors.each do |key, error|
      error = error.first
      field_error = tmpl :field_error
      field_error.html error_name(key, error)

      field = dom.find("input[name='#{key}']")
      field.before field_error.dom
    end
  end

  def error_name key, error
    case error.to_sym
    when :not_email
      'Email Isn\'t Valid.'
    when :not_present
      'Required.'
    when :not_equal
      'Password does not match.'
    else
      error
    end
  end
end
