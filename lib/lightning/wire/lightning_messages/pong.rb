# frozen_string_literal: true

require 'lightning/wire/lightning_messages/pong.pb'

module Lightning
  module Wire
    module LightningMessages
      class Pong < Lightning::Wire::LightningMessages::Generated::Pong
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 19

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def valid?
          return false if ignored.empty?
          true
        end
      end
    end
  end
end
