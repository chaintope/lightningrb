# frozen_string_literal: true

module Lightning
  module Blockchain
    class Watcher < Concurrent::Actor::Context
      include Concurrent::Concern::Logging
      include Lightning::Utils::Algebrick
      include Algebrick::Matching
      include Lightning::Blockchain::Messages

      Timeout = Algebrick.atom

      def initialize(wallet)
        @wallet = wallet
        @watchings = []
        @block_height = @wallet.spv.chain.latest_block.height
        @wallet.spv.add_observer(self)
      end

      def update(event, data)
        log(Logger::DEBUG, "update : #{event}:#{data.inspect}")
        case event
        when :tx
          tx = data.tx
          txid = tx.txid
          @watchings.each do |w|
            next unless w[:txid] == txid
            if w[:blocks]
              @watchings.delete(w)
              @watchings << w.merge(event_type: 'confirmed', height: @block_height + w[:blocks], tx: tx)
              @watchings << w.merge(event_type: 'deeply_confirmed', height: @block_height + w[:buried], tx: tx) # for notification of `deeply` confirmed.
            end
          end

          tx.outputs.each_with_index do |output, index|
            found_target = @wallet.spv.wallet.watch_targets.find do |target|
              output.script_pubkey == Bitcoin::Script.to_p2wpkh(target)
            end
            next unless found_target
            @wallet.add_utxo(txid, index, output.value, output.script_pubkey.to_payload.bth, '')
          end

          tx.inputs.each do |input|
            txid = input.out_point.hash.rhex
            index = input.out_point.index
            @wallet.remove_utxo(txid, index)
          end
        when :merkleblock
          tree = Bitcoin::MerkleTree.build_partial(data.tx_count, data.hashes, Bitcoin.byte_to_bit(data.flags.htb))
          tx_blockhash = data.header.block_hash
          @watchings.each do |w|
            next unless data.hashes.include?(w[:txid].rhex)
            @watchings.delete(w)
            tx_index = tree.find_node(w[:txid].rhex).index
            @watchings << w.merge(tx_index: tx_index, tx_blockhash: tx_blockhash)
          end
        when :header
          block_height = data[:height]
          return if @block_height >= block_height
          @block_height = block_height
          @watchings.each do |w|
            if w[:height] && (block_height >= w[:height])
              tx = w[:tx]
              next unless w[:tx_blockhash]
              tx_height = @wallet.spv.chain.find_entry_by_hash(w[:tx_blockhash]).height
              @watchings.delete(w)
              w[:listener] << WatchEventConfirmed[w[:event_type], tx_height, w[:tx_index]]
            end
          end
        end
      end

      def on_message(message)
        match message, (on WatchConfirmed.(~any, ~any, ~any) do |listener, txid, blocks|
          @wallet.spv.filter_add(txid.rhex)
          @watchings << { txid: txid, blocks: blocks, buried: 6, listener: listener }
        end), (on :watchings do
          @watchings
        end)
      end
    end
  end
end
