# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module Error
        def self.load(payload)
          _, channel_id, len, rest = payload.unpack('nH64na*')
          return nil if len.nil?
          return nil if rest.nil?
          return nil if len > rest.bytesize
          data, = rest[0..len].bth
          new(channel_id, len, data)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::ERROR
        end

        def to_payload
          payload = +''
          payload << [Error.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:len]].pack('n')
          payload << self[:data].htb
          payload
        end
      end
    end
  end
end
