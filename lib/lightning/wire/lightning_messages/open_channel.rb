# frozen_string_literal: true

require 'lightning/wire/lightning_messages/open_channel.pb'

module Lightning
  module Wire
    module LightningMessages
      class OpenChannel < Lightning::Wire::LightningMessages::Generated::OpenChannel
        include Lightning::Exceptions
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::OpenMessage
        include Lightning::Wire::LightningMessages::HasTemporaryChannelId
        TYPE = 32

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        MAX_FUNDING_SATOSHIS = 2**24 - 1
        MIN_FUNDING_SATOSHIS = 100_000 # TODO: NodeParams?

        def validate!
          raise AmountTooLarge.new(self.temporary_channel_id,self[:funding_satoshis], MAX_FUNDING_SATOSHIS) if self[:funding_satoshis] > MAX_FUNDING_SATOSHIS
          raise PushMsatTooLarge.new(self.temporary_channel_id, self[:push_msat], self[:funding_satoshis]) if self[:push_msat] > self[:funding_satoshis] * 1_000
          raise InvalidKeyFormat.new(self.temporary_channel_id, self[:funding_pubkey]) unless valid_pubkey?(self[:funding_pubkey])
          raise InvalidKeyFormat.new(self.temporary_channel_id, self[:revocation_basepoint]) unless valid_pubkey?(self[:revocation_basepoint])
          raise InvalidKeyFormat.new(self.temporary_channel_id, self[:payment_basepoint]) unless valid_pubkey?(self[:payment_basepoint])
          raise InvalidKeyFormat.new(self.temporary_channel_id, self[:delayed_payment_basepoint]) unless valid_pubkey?(self[:delayed_payment_basepoint])
          raise InvalidKeyFormat.new(self.temporary_channel_id, self[:htlc_basepoint]) unless valid_pubkey?(self[:htlc_basepoint])
          raise InvalidKeyFormat.new(self.temporary_channel_id, self[:first_per_commitment_point]) unless valid_pubkey?(self[:first_per_commitment_point])
          raise InsufficientChannelReserve.new(self.temporary_channel_id, self[:channel_reserve_satoshis]) if self[:channel_reserve_satoshis] < self[:dust_limit_satoshis]
        end

        def valid_pubkey?(key)
          Bitcoin::Key.new(pubkey: key).fully_valid_pubkey?
        rescue ECDSA::Format::DecodeError => e
          return false
        end
      end
    end
  end
end
