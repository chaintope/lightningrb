# frozen_string_literal: true

FactoryBot.define do
  factory(:publishable_tx, class: 'FactoryBotWrapper') do
    commit_tx { build(:transaction_with_utxo).get }
    htlc_txs_and_sigs { [] }
    initialize_with do
      new(Lightning::Channel::Messages::PublishableTxs[commit_tx, htlc_txs_and_sigs])
    end
  end
end
