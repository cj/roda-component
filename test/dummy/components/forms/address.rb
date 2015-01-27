module Forms
  class Address < Roda::Component::Form
    attr_accessor :line1, :line2, :city, :zip

    def validate
      assert_present :line1
      assert_present :city
      assert_present :zip
    end
  end
end
