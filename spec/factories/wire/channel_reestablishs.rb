# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_reestablish, class: 'Lightning::Wire::LightningMessages::ChannelReestablish') do
    channel_id { '00' * 32 }
    next_local_commitment_number { 1 }
    next_remote_revocation_number { 1 }
    your_last_per_commitment_secret { '00' * 32 }
    my_current_per_commitment_point { '00' * 33 }
  end
end
