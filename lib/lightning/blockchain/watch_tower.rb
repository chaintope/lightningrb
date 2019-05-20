# frozen_string_literal: true

module Lightning
  module Blockchain
    class WatchTower < Concurrent::Actor::Context
      class Register
        attr_reader :head_tx_hash, :encrypted_payload
        def initialize(head_tx_hash: '00' * 16, encrypted_payload: '')
          @head_tx_hash = head_tx_hash
          @encrypted_payload = encrypted_payload
        end
      end

      def initialize(context)
        @context = context
        @transactions = {}
        @stub = create_grpc_client(context.spv)
      end

      def on_message(message)
        case message
        when Register
          @transactions[message.head_tx_hash] ||= []
          @transactions[message.head_tx_hash] << message.encrypted_payload
          request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(id: 0, tx_hash: message.head_tx_hash, confirmations: 0)
          @stub.watch_tx_confirmed(request)
        when Bitcoin::Grpc::TxReceived
          head = message.tx_hash[0...32]
          cipher = RbNaCl::AEAD::ChaCha20Poly1305IETF.new(message.tx_hash.htb)
          broadcasted = @transactions[head]&.map do |transaction|
            begin
              payload = cipher.decrypt("\x00" * 12, transaction.htb, '')
              tx = Bitcoin::Tx.parse_from_payload(payload)
              @context.spv.broadcast(tx)
              transaction
            rescue ::RbNaCl::CryptoError => e
            end
          end
          broadcasted&.each { |t| @transactions[head].delete(t) }
          @transactions.delete(head) if @transactions[head]&.empty?
        when :transactions
          @transactions
        end
      end

      def create_grpc_client(spv)
        stub = Bitcoin::Grpc::Blockchain::Stub.new(spv.build_bitcoin_grpc_url, :this_channel_is_insecure)
        requests = [Bitcoin::Grpc::EventsRequest.new(operation: :SUBSCRIBE, event_type: "Bitcoin::Grpc::TxReceived")]
        stub.events(requests).each do |reponse|
          reference << response
        end
        stub
      end
    end
  end
end
