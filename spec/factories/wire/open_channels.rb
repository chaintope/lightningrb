# frozen_string_literal: true

FactoryBot.define do
  factory(:open_channel, class: 'FactoryBotWrapper') do
    chain_hash '821c2ed9a347077ed90175802c9b06735222359091e7b5cc8edd3e1d62067842'
    temporary_channel_id '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357'
    funding_satoshis 1_000_000
    push_msat 4
    dust_limit_satoshis 546
    max_htlc_value_in_flight_msat 100_000
    channel_reserve_satoshis 10_000
    htlc_minimum_msat 0
    feerate_per_kw 9
    to_self_delay 144
    max_accepted_htlcs 11
    funding_pubkey { build(:key, :local_funding_pubkey).pubkey }
    revocation_basepoint { build(:revocation_basepoint) }
    payment_basepoint { build(:payment_basepoint) }
    delayed_payment_basepoint { build(:delayed_payment_basepoint) }
    htlc_basepoint { build(:htlc_basepoint) }
    first_per_commitment_point { build(:first_per_commitment_point) }
    channel_flags 1
    initialize_with do
      new(Lightning::Wire::LightningMessages::OpenChannel[
        chain_hash,
        temporary_channel_id,
        funding_satoshis,
        push_msat,
        dust_limit_satoshis,
        max_htlc_value_in_flight_msat,
        channel_reserve_satoshis,
        htlc_minimum_msat,
        feerate_per_kw,
        to_self_delay,
        max_accepted_htlcs,
        funding_pubkey,
        revocation_basepoint,
        payment_basepoint,
        delayed_payment_basepoint,
        htlc_basepoint,
        first_per_commitment_point,
        channel_flags
      ])
    end
  end
end
