# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module Shutdown
        def self.load(payload)
          _, channel_id, len, rest = payload.unpack('nH64na*')
          scriptpubkey, = rest.unpack("H#{len * 2}")
          new(channel_id, len, scriptpubkey)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::SHUTDOWN
        end

        def to_payload
          payload = +''
          payload << [Shutdown.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:len]].pack('n')
          payload << self[:scriptpubkey].htb
          payload
        end
      end
    end
  end
end
