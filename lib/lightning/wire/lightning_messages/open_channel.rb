# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module OpenChannel
        include Lightning::Exceptions

        MAX_FUNDING_SATOSHIS = 2**24 - 1
        MIN_FUNDING_SATOSHIS = 100_000 # TODO: NodeParams?

        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64H64q>6Nn2H66H66H66H66H66H66c'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::OPEN_CHANNEL
        end

        def to_payload
          payload = +''
          payload << [OpenChannel.to_type].pack('n')
          payload << self[:chain_hash].htb
          payload << self[:temporary_channel_id].htb
          payload << [
            self[:funding_satoshis],
            self[:push_msat],
            self[:dust_limit_satoshis],
            self[:max_htlc_value_in_flight_msat],
            self[:channel_reserve_satoshis],
            self[:htlc_minimum_msat],
            self[:feerate_per_kw],
            self[:to_self_delay],
            self[:max_accepted_htlcs],
          ].pack('q>6Nn2')
          payload << self[:funding_pubkey].htb
          payload << self[:revocation_basepoint].htb
          payload << self[:payment_basepoint].htb
          payload << self[:delayed_payment_basepoint].htb
          payload << self[:htlc_basepoint].htb
          payload << self[:first_per_commitment_point].htb
          payload << [self[:channel_flags]].pack('c')

          # option_upfront_shutdown_script
          # payload << [self[:shutdown_len]].pack('n')
          # payload << self[:shutdown_scriptpubkey]
          payload
        end

        def validate!
          raise AmountTooLarge.new(self[:funding_satoshis], MAX_FUNDING_SATOSHIS) if self[:funding_satoshis] > MAX_FUNDING_SATOSHIS
          raise PushMsatTooLarge.new(self[:push_msat], self[:funding_satoshis]) if self[:push_msat] > self[:funding_satoshis] * 1_000
          raise InvalidKeyFormat.new(self[:funding_pubkey]) unless valid_pubkey?(self[:funding_pubkey])
          raise InvalidKeyFormat.new(self[:revocation_basepoint]) unless valid_pubkey?(self[:revocation_basepoint])
          raise InvalidKeyFormat.new(self[:payment_basepoint]) unless valid_pubkey?(self[:payment_basepoint])
          raise InvalidKeyFormat.new(self[:delayed_payment_basepoint]) unless valid_pubkey?(self[:delayed_payment_basepoint])
          raise InvalidKeyFormat.new(self[:htlc_basepoint]) unless valid_pubkey?(self[:htlc_basepoint])
          raise InvalidKeyFormat.new(self[:first_per_commitment_point]) unless valid_pubkey?(self[:first_per_commitment_point])
          raise InsufficientChannelReserve.new(self[:channel_reserve_satoshis]) if self[:channel_reserve_satoshis] < self[:dust_limit_satoshis]
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
