# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_update, class: 'FactoryBotWrapper') do
    signature do
      '304402203b5969880d01a90c34ea3999eb78e6bd476603db6bd0ba96742a3e60' \
      '0b0eaebc022000aa488c80e8e949452b471bc6d5f15e48bd10c8b4cb1c3f7e76' \
      'a55d68643725'
    end
    chain_hash { '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f' }
    short_channel_id { 1 }
    timestamp { 2 }
    message_flags { 2 }
    channel_flags { 1 }
    cltv_expiry_delta { 3 }
    htlc_minimum_msat { 4 }
    fee_base_msat { 5 }
    fee_proportional_millionths { 6 }

    initialize_with do
      new(Lightning::Wire::LightningMessages::ChannelUpdate[
        signature,
        chain_hash,
        short_channel_id,
        timestamp,
        message_flags,
        channel_flags,
        cltv_expiry_delta,
        htlc_minimum_msat,
        fee_base_msat,
        fee_proportional_millionths
      ])
    end
  end
end
