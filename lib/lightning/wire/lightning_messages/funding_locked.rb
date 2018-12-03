# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module FundingLocked
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64H66'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::FUNDING_LOCKED
        end

        def to_payload
          payload = +''
          payload << [FundingLocked.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << self[:next_per_commitment_point].htb
          payload
        end
      end
    end
  end
end
