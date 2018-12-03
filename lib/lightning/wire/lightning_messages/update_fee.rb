# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module UpdateFee
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64N'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::UPDATE_FEE
        end

        def to_payload
          payload = +''
          payload << [UpdateFee.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:feerate_per_kw]].pack('N')
          payload
        end
      end
    end
  end
end
