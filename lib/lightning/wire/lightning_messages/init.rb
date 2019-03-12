# frozen_string_literal: true

require 'lightning/wire/lightning_messages/init.pb'

module Lightning
  module Wire
    module LightningMessages
      class Init < Lightning::Wire::LightningMessages::Generated::Init
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 16

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end
