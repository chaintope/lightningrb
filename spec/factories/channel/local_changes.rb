# frozen_string_literal: true

FactoryBot.define do
  factory(:local_change, class: 'FactoryBotWrapper') do
    proposed { [] }
    signed { [] }
    acked { [] }
    initialize_with do
      new(Lightning::Channel::Messages::LocalChanges[proposed, signed, acked])
    end
  end
end
