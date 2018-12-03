# frozen_string_literal: true

FactoryBot.define do
  factory(:remote_change, class: 'FactoryBotWrapper') do
    proposed { [] }
    acked { [] }
    signed { [] }
    initialize_with do
      new(Lightning::Channel::Messages::RemoteChanges[proposed, acked, signed])
    end
  end
end
