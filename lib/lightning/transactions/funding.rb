# frozen_string_literal: true

module Lightning
  module Transactions
    module Funding
      def self.make_funding_tx(wallet, funding_pubkey_script, funding_satoshis, funding_tx_feerate_per_kw)
        tx = Bitcoin::Tx.new
        tx.version = 2
        tx.outputs << Bitcoin::TxOut.new(value: funding_satoshis, script_pubkey: funding_pubkey_script)
        tx.lock_time = 0
        signed_tx = wallet&.complete(tx)
        MakeFundingTxResponse[signed_tx, 0]
      end

      def self.make_funding_utxo(funding_tx_txid, funding_tx_output_index, funding_satoshis, local_funding_pubkey, remote_funding_pubkey)
        redeem_script = pubkey_script(local_funding_pubkey, remote_funding_pubkey)
        script_pubkey = Bitcoin::Script.to_p2wsh(redeem_script)
        Lightning::Transactions::Utxo.new(funding_satoshis, script_pubkey, funding_tx_txid, funding_tx_output_index, redeem_script)
      end

      def self.pubkey_script(local_key, remote_key)
        puts "pubkey_script(local_key, remote_key)=#{local_key}/#{remote_key}"
        keys =
          if Lightning::Utils::LexicographicalOrdering.less_than?(local_key, remote_key)
            [local_key, remote_key]
          else
            [remote_key, local_key]
          end
        Bitcoin::Script.to_multisig_script(2, keys)
      end
      MakeFundingTxResponse = Algebrick.type do
        fields! tx: Bitcoin::Tx,
                index: Numeric
      end
    end
  end
end
