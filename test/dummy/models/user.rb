module Models
  class User < Sequel::Model
    include Shield::Model

    class << self
      def fetch email
        # TODO: Case insensitive emails? Force lowercase?
        if user = Models::User.where(email: email)
          user.first
        else
          false
        end
      end
    end
  end
end
