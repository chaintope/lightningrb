# frozen_string_literal: true

FactoryBot.define do
  factory(:broadcast, class: 'Concurrent::Actor::Reference') do
    initialize_with do
      Lightning::IO::Broadcast.spawn(:broadcast)
    end
  end
end
