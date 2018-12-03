# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module Init
        def self.load(payload)
          _, rest = payload.unpack('na*')
          gflen, rest = rest.unpack('na*')
          return nil if rest.nil?
          return nil if expected_size?(gflen, rest)
          globalfeatures = rest[0...gflen].bth
          rest = rest[gflen..-1]
          lflen, rest = rest.unpack('na*')
          return nil if rest.nil?
          return nil if expected_size?(lflen, rest)
          localfeatures = rest[0...lflen].bth
          new(gflen, globalfeatures, lflen, localfeatures)
        end

        def self.expected_size?(len, rest)
          len.nil? || len > rest.bytesize
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::INIT
        end

        def to_payload
          payload = +''
          payload << [Init.to_type, self[:gflen]].pack('n2')
          payload << self[:globalfeatures].htb
          payload << [self[:lflen]].pack('n')
          payload << self[:localfeatures].htb
          payload
        end
      end
    end
  end
end
