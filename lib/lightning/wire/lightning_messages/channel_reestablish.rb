# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module ChannelReestablish
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64q>2'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::CHANNEL_REESTABLISH
        end

        def to_payload
          payload = +''
          payload << [ChannelReestablish.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:next_local_commitment_number], self[:next_remote_revocation_number]].pack('q>2')
          ## option-data-loss-protect
          # payload << self[:your_last_per_commitment_secret]
          # payload << self[:my_current_per_commitment_point]
          payload
        end
      end
    end
  end
end
