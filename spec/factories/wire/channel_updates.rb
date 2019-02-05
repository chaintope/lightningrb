# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_update, class: 'Lightning::Wire::LightningMessages::ChannelUpdate') do
    signature { build(:signature) }
    chain_hash { '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f' }
    short_channel_id { 1 }
    timestamp { 2 }
    message_flags { '02' }
    channel_flags { '01' }
    cltv_expiry_delta { 3 }
    htlc_minimum_msat { 4 }
    fee_base_msat { 5 }
    fee_proportional_millionths { 6 }
    htlc_maximum_msat { 7 }
  end
end
