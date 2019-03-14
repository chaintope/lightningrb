# frozen_string_literal: true

require 'lightning/wire/lightning_messages/channel_reestablish.pb'

module Lightning
  module Wire
    module LightningMessages
      class ChannelReestablish < Lightning::Wire::LightningMessages::Generated::ChannelReestablish
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        TYPE = 136

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end
