# frozen_string_literal: true

FactoryBot.define do
  factory(:node_param, class: 'Lightning::NodeParams') do
    node_id { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    ping_interval { 0 }
    private_key { '4141414141414141414141414141414141414141414141414141414141414141' }
    extended_private_key { Bitcoin::ExtKey.generate_master('00' * 32) }
    dust_limit_satoshis { 0 }
    max_htlc_value_in_flight_msat { 0 }
    reserve_to_funding_ratio { 0 }
    htlc_minimum_msat { 0 }
    delay_blocks { 0 }
    max_accepted_htlcs { 0 }
    globalfeatures { "\x00" }
    localfeatures { "\x00" }
    feerates_per_kw { 0 }
    chain_hash { 'ff' * 32 }
    min_depth_blocks { 1 }
  end
end
