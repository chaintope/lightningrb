# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_update, class: 'Lightning::Wire::LightningMessages::ChannelUpdate') do
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

    initialize_with do
      node_key = build(:key, :remote_funding_privkey)
      witness = Lightning::Wire::LightningMessages::ChannelUpdate.witness(chain_hash,
        short_channel_id,
        timestamp,
        message_flags,
        channel_flags,
        cltv_expiry_delta,
        htlc_minimum_msat,
        fee_base_msat,
        fee_proportional_millionths,
        htlc_maximum_msat
      )
      signature = Lightning::Wire::Signature.new(value: node_key.sign(witness).bth)
      new(
        signature: signature,
        chain_hash: chain_hash,
        short_channel_id: short_channel_id,
        timestamp: timestamp,
        message_flags: message_flags,
        channel_flags: channel_flags,
        cltv_expiry_delta: cltv_expiry_delta,
        htlc_minimum_msat: htlc_minimum_msat,
        fee_base_msat: fee_base_msat,
        fee_proportional_millionths: fee_proportional_millionths,
        htlc_maximum_msat: htlc_maximum_msat
      )
    end
  end
end
