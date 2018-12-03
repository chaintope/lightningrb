# frozen_string_literal: true

module Lightning
  module Transactions
    TransactionWithUtxo = ::Algebrick.type do
      fields! tx: Bitcoin::Tx,
              utxo: Lightning::Transactions::Utxo
    end
  end
end
