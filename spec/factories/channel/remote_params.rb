# frozen_string_literal: true

FactoryBot.define do
  factory(:remote_param, class: 'FactoryBotWrapper') do
    node_id { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    dust_limit_satoshis { 546 }
    max_htlc_value_in_flight_msat { 100_000_000 }
    channel_reserve_satoshis { 7 }
    htlc_minimum_msat { 5_000_000 }
    to_self_delay { 144 }
    max_accepted_htlcs { 483 }
    funding_pubkey { build(:key, :remote_funding_pubkey).pubkey }
    revocation_basepoint { build(:revocation_basepoint) }
    payment_basepoint { build(:payment_basepoint) }
    delayed_payment_basepoint { build(:delayed_payment_basepoint) }
    htlc_basepoint { build(:htlc_basepoint) }
    globalfeatures { build(:globalfeatures) }
    localfeatures { build(:localfeatures) }
    initialize_with do
      new(Lightning::Channel::Messages::RemoteParam[
        node_id,
        dust_limit_satoshis,
        max_htlc_value_in_flight_msat,
        channel_reserve_satoshis,
        htlc_minimum_msat,
        to_self_delay,
        max_accepted_htlcs,
        funding_pubkey,
        revocation_basepoint,
        payment_basepoint,
        delayed_payment_basepoint,
        htlc_basepoint,
        globalfeatures,
        localfeatures
      ])
    end
  end
end
