# frozen_string_literal: true

FactoryBot.define do
  factory(:input_init_funder, class: 'FactoryBotWrapper') do
    temporary_channel_id { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    funding_satoshis { 10_000_000 }
    push_msat { 4 }
    initial_feerate_per_kw { 15000 }
    local_param { build(:local_param).get }
    remote { spawn_dummy_actor }
    remote_init { build(:init) }
    channel_flags { 0 }

    initialize_with do
      new(Lightning::Channel::Messages::InputInitFunder[
          temporary_channel_id,
          funding_satoshis,
          push_msat,
          initial_feerate_per_kw,
          local_param,
          remote,
          remote_init,
          channel_flags,
          ''
        ])
    end
  end
end
