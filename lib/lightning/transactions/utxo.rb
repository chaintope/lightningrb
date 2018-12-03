# frozen_string_literal: true

module Lightning
  module Transactions
    class Utxo
      attr_reader :value, :script_pubkey, :txid, :index, :redeem_script

      def initialize(value, script_pubkey, txid, index, redeem_script)
        @value = value
        @script_pubkey = script_pubkey
        @txid = txid
        @index = index
        @redeem_script = redeem_script
      end

      def coinbase?
        @coinbase
      end

      def out_point
        @out_point ||= Bitcoin::OutPoint.from_txid(@txid, @index)
      end

      def key?(key)
        script_pubkey == Bitcoin::Script.to_p2wpkh(key.hash160).to_payload.bth
      end

      def self.load(payload)
        value, len, rest = payload.unpack('q>na*')
        script_pubkey, txid, index, len, rest = rest.unpack("a#{len}H64nna*")
        redeem_script, rest = rest.unpack("a#{len}a*")
        [
          new(
            value,
            Bitcoin::Script.parse_from_payload(script_pubkey),
            txid,
            index,
            Bitcoin::Script.parse_from_payload(redeem_script)
          ),
          rest,
        ]
      end

      def to_payload
        [
          value,
          script_pubkey.to_payload.bytesize,
          script_pubkey.to_payload,
          txid,
          index,
          redeem_script.to_payload.bytesize,
          redeem_script.to_payload,
        ].pack("q>na#{script_pubkey.to_payload.bytesize}H64nna#{redeem_script.to_payload.bytesize}")
      end
    end
  end
end
