require 'roda/component/form'
require_relative 'address'

module Forms
  class Login < Roda::Component::Form
    attr_accessor :name, :email, :phone, :address

    def validate
      assert_present :name
      assert_present :email
      assert_present :address, Forms::Address
    end
  end
end
