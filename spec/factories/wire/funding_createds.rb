# frozen_string_literal: true

FactoryBot.define do
  factory(:funding_created, class: 'FactoryBotWrapper') do
    temporary_channel_id { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    funding_txid { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6be' }
    funding_output_index { 0 }

    signature do
      '3044022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319' \
      'e5185a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b' \
      '1937c3836939'
    end

    initialize_with do
      new(Lightning::Wire::LightningMessages::FundingCreated[
        temporary_channel_id,
        funding_txid,
        funding_output_index,
        signature
      ])
    end
  end
end
