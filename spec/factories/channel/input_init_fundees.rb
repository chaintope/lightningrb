# frozen_string_literal: true

FactoryBot.define do
  factory(:input_init_fundee, class: 'FactoryBotWrapper') do
    temporary_channel_id { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    local_param { build(:local_param).get }
    remote { spawn_dummy_actor }
    remote_init { build(:init).get }

    initialize_with do
      new(Lightning::Channel::Messages::InputInitFundee[
        temporary_channel_id,
        local_param,
        remote,
        remote_init
      ])
    end
  end
end
