# frozen_string_literal: true

FactoryBot.define do
  factory(:local_param, class: 'FactoryBotWrapper') do
    node_id { '034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa' }
    dust_limit_satoshis { 546 }
    max_htlc_value_in_flight_msat { 100_000_000 }
    channel_reserve_satoshis { 600 }
    htlc_minimum_msat { 5_000_000 }
    to_self_delay { 144 }
    max_accepted_htlcs { 483 }
    funding_priv_key { build(:key, :local_funding_privkey) }
    revocation_secret { 13 }
    payment_key { 14 }
    delayed_payment_key { 15 }
    htlc_key { 16 }
    default_final_script_pubkey { '001429f97a569a8013d3608bfb15392eb8082ff8d2aa' }
    sha_seed { "11" * 32 }
    funder { 1 }
    globalfeatures { build(:globalfeatures) }
    localfeatures { build(:localfeatures) }
    initialize_with do
      new(Lightning::Channel::Messages::LocalParam[
            node_id,
            dust_limit_satoshis,
            max_htlc_value_in_flight_msat,
            channel_reserve_satoshis,
            htlc_minimum_msat,
            to_self_delay,
            max_accepted_htlcs,
            funding_priv_key,
            revocation_secret,
            payment_key,
            delayed_payment_key,
            htlc_key,
            default_final_script_pubkey,
            sha_seed,
            funder,
            globalfeatures,
            localfeatures
      ])
    end

    trait :funder do
      funder { 1 }
    end

    trait :fundee do
      funder { 0 }
    end
  end
end
