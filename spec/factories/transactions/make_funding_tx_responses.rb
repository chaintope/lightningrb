# frozen_string_literal: true

FactoryBot.define do
  factory(:make_funding_tx_response, class: 'FactoryBotWrapper') do
    tx { Bitcoin::Tx.new }
    index 0
    initialize_with do
      new(Lightning::Transactions::Funding::MakeFundingTxResponse[tx, index])
    end
  end
end
