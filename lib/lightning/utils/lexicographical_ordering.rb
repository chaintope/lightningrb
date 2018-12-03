# frozen_string_literal: true

module Lightning
  module Utils
    module LexicographicalOrdering
      def self.sort(tx)
        inputs = sort_inputs(tx.inputs)
        outputs = sort_outputs(tx.outputs)
        tx.inputs.clear
        tx.outputs.clear
        inputs.each { |input| tx.inputs << input }
        outputs.each { |output| tx.outputs << output }
        tx
      end

      def self.sort_inputs(inputs)
        inputs.sort do |a, b|
          next (a.out_point.index <=> b.out_point.index) if a.out_point.txid == b.out_point.txid
          a.out_point.txid <=> b.out_point.txid
        end
      end

      def self.sort_outputs(outputs)
        outputs.sort do |a, b|
          next a.script_pubkey.to_payload <=> b.script_pubkey.to_payload if a.value == b.value
          a.value - b.value
        end
      end

      def self.less_than?(key1, key2)
        key1 < key2
      end
    end
  end
end
