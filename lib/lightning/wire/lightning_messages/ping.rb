# frozen_string_literal: true

require 'lightning/wire/lightning_messages/ping.pb'

module Lightning
  module Wire
    module LightningMessages
      class Ping < Lightning::Wire::LightningMessages::Generated::Ping
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 18

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def valid?
          return false if num_pong_bytes == 0
          return false if ignored.empty?
          true
        end
      end
    end
  end
end
