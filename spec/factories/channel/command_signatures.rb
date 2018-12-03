# frozen_string_literal: true

FactoryBot.define do
  factory(:command_signature, class: 'FactoryBotWrapper') do
    initialize_with do
      new(Lightning::Channel::Messages::CommandSignature)
    end
  end
end
