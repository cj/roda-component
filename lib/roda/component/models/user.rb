class Roda
  class Component
    module Models
      class User < Ohm::Model
        attribute :model_id
        index :model_id

        collection :channels, 'Roda::Component::Models::Channel'
      end
    end
  end
end
