# frozen_string_literal: true

FactoryBot.define do
  factory(:command_fulfill_htlc, class: 'FactoryBotWrapper') do
    id { 0 }
    r { Bitcoin.sha256("\x42" * 32).bth }
    commit { true }
    initialize_with do
      new(Lightning::Channel::Messages::CommandFulfillHtlc[id, r, commit])
    end
  end
end
