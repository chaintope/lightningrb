# frozen_string_literal: true

FactoryBot.define do
  factory(:init, class: 'FactoryBotWrapper') do
    gflen { 1 }
    globalfeatures { FactoryBot.build(:localfeatures) }
    lflen { 2 }
    localfeatures { FactoryBot.build(:localfeatures) }

    initialize_with do
      new(Lightning::Wire::LightningMessages::Init[gflen, globalfeatures, lflen, localfeatures])
    end
  end
end
