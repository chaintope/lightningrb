# frozen_string_literal: true

FactoryBot.define do
  factory(:init, class: 'Lightning::Wire::LightningMessages::Init') do
    globalfeatures { FactoryBot.build(:localfeatures) }
    localfeatures { FactoryBot.build(:localfeatures) }
  end
end
