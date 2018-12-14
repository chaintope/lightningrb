# frozen_string_literal: true

FactoryBot.define do
  factory(:command_update_fee, class: 'FactoryBotWrapper') do
    feerate_per_kw { 100 }
    commit { true }
    initialize_with do
      new(Lightning::Channel::Messages::CommandUpdateFee[feerate_per_kw, commit])
    end
  end
end
