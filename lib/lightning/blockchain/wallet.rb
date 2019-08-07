# frozen_string_literal: true

module Lightning
  module Blockchain
    class Wallet
      attr_reader :spv, :context

      def initialize(spv, context)
        @context = context
        @spv = spv
      end

      def complete(tx, account_name, outputs, options: {})
        outputs.each { |output| tx.outputs << output }
        amount = tx.outputs.sum(&:value)
        sum = 0
        utxos = spv.list_unspent(account_name)
        utxos.each do |utxo|
          out_point = Bitcoin::OutPoint.new(utxo['tx_hash'], utxo['index'])
          tx.inputs << Bitcoin::TxIn.new(out_point: out_point)
          sum += utxo['value']
          break if sum >= amount
        end
        raise Lightning::Exceptions::InsufficientFundsInWallet.new(sum, amount) if sum < amount
        complete_change(account_name, sum, amount, tx)
        signed_tx = sign(tx, account_name)
        signed_tx
      end

      def sign(tx, account_name)
        sign = spv.sign_transaction(account_name, tx)
        Bitcoin::Tx.parse_from_payload(sign["hex"].htb)
      end

      def complete_change(account_name, sum, amount, tx)
        return if sum == amount
        # FIXME
        fee = 10_000
        address = spv.generate_new_address(account_name)
        script = Bitcoin::Script.parse_from_addr(address)
        tx.outputs << Bitcoin::TxOut.new(value: sum - amount - fee, script_pubkey: script)
      end

      def commit(tx)
        spv.broadcast(tx)
        tx
      end

      def to_s
        "Wallet"
      end
    end
  end
end
