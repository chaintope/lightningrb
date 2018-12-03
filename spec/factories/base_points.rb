# frozen_string_literal: true

FactoryBot.define do
  factory(:revocation_basepoint, class: 'String') do
    initialize_with { new('024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead80ac9423374c451a7254d0766') }
  end
  factory(:payment_basepoint, class: 'String') do
    initialize_with { new('02531fe6068134503d2723133227c867ac8fa6c83c537e9a44c3c5bdbdcb1fe337') }
  end
  factory(:delayed_payment_basepoint, class: 'String') do
    initialize_with { new('03462779ad4aad39514614751a71085f2f10e1c7a593e4e030efb5b8721ce55b0b') }
  end
  factory(:htlc_basepoint, class: 'String') do
    initialize_with { new('0362c0a046dacce86ddd0343c6d3c7c79c2208ba0d9c9cf24a6d046d21d21f90f7') }
  end
  factory(:first_per_commitment_point, class: 'String') do
    initialize_with { new('03f006a18d5653c4edf5391ff23a61f03ff83d237e880ee61187fa9f379a028e0a') }
  end
  factory(:remote_first_per_commitment_point, class: 'String') do
    initialize_with { new('03f006a18d5653c4edf5391ff23a61f03ff83d237e880ee61187fa9f379a028e0a') }
  end
end
