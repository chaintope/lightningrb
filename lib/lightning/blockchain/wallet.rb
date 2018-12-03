# frozen_string_literal: true

module Lightning
  module Blockchain
    class Wallet
      attr_reader :spv
      attr_reader :utxo_db

      def initialize(spv)
        @spv = spv
        @utxo_db = Lightning::Store::UtxoDb.new('tmp/utxo_db')
      end

      def ext_keys
        spv.wallet.accounts.map do |a|
          account_key = spv.wallet.master_key.derive(a.path)
          (0..a.receive_depth).map do |depth|
            account_key.derive(0).derive(depth)
          end + (0..a.change_depth).map do |depth|
            account_key.derive(1).derive(depth)
          end
        end.flatten
      end

      def new_receive_key
        account = spv.wallet.accounts.first
        ext_key = account.create_receive
        ext_key.key
      end

      def new_receive_address
        new_receive_key&.to_p2wpkh
        # account.derive_receive(account.receive_depth)
      end

      def search_for(utxo)
        found = ext_keys.find { |ext_key| utxo.key?(ext_key) }
        found&.key
      end

      def complete(tx)
        amount = tx.outputs.sum(&:value)
        sum = 0
        utxos_for_input = {}
        utxos.each do |utxo|
          tx.inputs << Bitcoin::TxIn.new(out_point: utxo.out_point)
          sum += utxo.value
          utxos_for_input[[utxo.txid, utxo.index]] = utxo
          break if sum >= amount
        end
        raise Lightning::Exceptions::InsufficientFundsInWallet.new(sum, amount) if sum < amount
        complete_change(sum, amount, tx)
        sign(tx, utxos_for_input)
        tx
      end

      def sign(tx, utxos_for_input)
        tx.inputs.each_with_index do |input, index|
          utxo = utxos_for_input[[input.out_point.txid, input.out_point.index]]
          script_pubkey = Bitcoin::Script.parse_from_payload(utxo.script_pubkey.htb)
          key = search_for(utxo)
          next unless key
          sighash = tx.sighash_for_input(
            index,
            script_pubkey,
            amount: utxo.value, sig_version: :witness_v0
          )
          witness = Bitcoin::ScriptWitness.new
          witness.stack << key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
          witness.stack << key.pubkey.htb
          input.script_witness = witness
          raise 'invalid sig' unless tx.verify_input_sig(index, script_pubkey, amount: utxo.value)
        end
      end

      def complete_change(sum, amount, tx)
        return if sum == amount
        fee = 10_000
        script = Bitcoin::Script.to_p2wpkh(Bitcoin.hash160(new_receive_key.pubkey))
        tx.outputs << Bitcoin::TxOut.new(value: sum - amount - fee, script_pubkey: script)
      end

      def commit(tx)
        spv&.broadcast(tx)
        tx
      end

      def close
        spv&.wallet&.close
      end

      def add_utxo(txid, index, value, script_pubkey, redeem_script)
        utxo_db.insert(txid, index, value, script_pubkey, redeem_script)
      end

      def remove_utxo(txid, index)
        utxo_db.delete(txid, index)
      end

      def utxos
        utxo_db.all.map do |utxo|
          Lightning::Transactions::Utxo.new(
            utxo[:value],
            utxo[:script_pubkey],
            utxo[:txid],
            utxo[:index],
            utxo[:redeem_script]
          )
        end
      end

      def to_s
        "Wallet"
      end
    end
  end
end
