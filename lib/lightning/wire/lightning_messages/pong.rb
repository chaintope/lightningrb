# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module Pong
        def self.load(payload)
          _, rest = payload.unpack('nH*')
          byteslen, rest = rest.htb.unpack('nH*')
          return nil if byteslen.nil?
          return nil if byteslen > rest&.htb&.bytesize
          ignored = rest&.htb&.byteslice(0, byteslen)
          new(byteslen, ignored)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::PONG
        end

        def to_payload
          payload = +''
          payload << [Pong.to_type, self[:byteslen]].pack('n2')
          payload << self[:ignored]
          payload
        end
      end
    end
  end
end
