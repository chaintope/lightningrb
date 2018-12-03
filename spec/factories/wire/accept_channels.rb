# frozen_string_literal: true

FactoryBot.define do
  factory(:accept_channel, class: 'FactoryBotWrapper') do
    temporary_channel_id '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357'
    dust_limit_satoshis 546
    max_htlc_value_in_flight_msat 6
    channel_reserve_satoshis 10_000
    htlc_minimum_msat 8
    minimum_depth 9
    to_self_delay 10
    max_accepted_htlcs 11
    funding_pubkey { build(:key, :remote_funding_pubkey).pubkey }
    revocation_basepoint { build(:revocation_basepoint) }
    payment_basepoint { build(:payment_basepoint) }
    delayed_payment_basepoint { build(:delayed_payment_basepoint) }
    htlc_basepoint { build(:htlc_basepoint) }
    first_per_commitment_point { build(:first_per_commitment_point) }
    initialize_with do
      new(Lightning::Wire::LightningMessages::AcceptChannel[
        temporary_channel_id,
        dust_limit_satoshis,
        max_htlc_value_in_flight_msat,
        channel_reserve_satoshis,
        htlc_minimum_msat,
        minimum_depth,
        to_self_delay,
        max_accepted_htlcs,
        funding_pubkey,
        revocation_basepoint,
        payment_basepoint,
        delayed_payment_basepoint,
        htlc_basepoint,
        first_per_commitment_point
      ])
    end
  end
end
