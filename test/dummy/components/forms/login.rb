require 'roda/component/form'

module Forms
  class Login < Roda::Component::Form
    attr_accessor :email, :password, :password_confirmation, :first_name, :last_name, :signup

    def validate
      assert_present :email
      assert_email :email
      assert_present :password

      if signup
        assert_present :first_name
        assert_present :last_name
        assert_present :password_confirmation
        assert_equal :password_confirmation, password
      end
    end
  end
end
