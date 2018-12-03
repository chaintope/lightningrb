# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module Ping
        def self.load(payload)
          _, rest = payload.unpack('nH*')
          num_pong_bytes, byteslen, rest = rest.htb.unpack('n2H*')
          return nil if byteslen.nil?
          return nil if byteslen > rest&.htb&.bytesize
          ignored = rest&.htb&.byteslice(0, byteslen)
          new(num_pong_bytes, byteslen, ignored)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::PING
        end

        def to_payload
          payload = +''
          payload << [Ping.to_type, self[:num_pong_bytes], self[:byteslen]].pack('n3')
          payload << self[:ignored]
          payload
        end
      end
    end
  end
end
