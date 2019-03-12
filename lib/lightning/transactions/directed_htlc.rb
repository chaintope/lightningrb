# frozen_string_literal: true

module Lightning
  module Transactions
    DirectedHtlc = Algebrick.type do
      fields! direction: Numeric, # 0: offered, 1: received
              add: Lightning::Wire::LightningMessages::UpdateAddHtlc
    end

    module DirectedHtlc
      def enough_amount(threshold)
        add.amount_msat >= threshold
      end

      def to_payload
        payload = StringIO.new
        payload << [self[:direction]].pack('C')
        add = self[:add].to_payload
        payload << [add.bytesize].pack('n')
        payload << add
        payload.string
      end

      def self.load(payload)
        direction, rest = payload.unpack('Ca*')
        len, rest = rest.unpack('na*')
        add = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest[0...len])
        [new(direction, add), rest[len..-1]]
      end
    end
  end
end
