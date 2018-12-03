# frozen_string_literal: true

FactoryBot.define do
  factory(:transaction_with_utxo, class: 'FactoryBotWrapper') do
    tx { Bitcoin::Tx.new }
    utxo { build(:utxo) }
    initialize_with do
      new(Lightning::Channel::Messages::TransactionWithUtxo[tx, utxo])
    end
  end
end
