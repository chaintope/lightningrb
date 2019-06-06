# frozen_string_literal: true

module Lightning
  module Blockchain
    class WatchTower < Concurrent::Actor::Context
      class Register
        attr_reader :head_tx_hash, :encrypted_payload, :delay
        def initialize(head_tx_hash: '00' * 16, encrypted_payload: '', delay: 0)
          @head_tx_hash = head_tx_hash
          @encrypted_payload = encrypted_payload
          @delay = delay
        end
      end

      class Publishable
        attr_reader :tx, :delay
        attr_accessor :block_height
        def initialize(tx, block_height: nil, delay: 0)
          @tx = tx
          @block_height = block_height
          @delay = delay
        end
      end

      def initialize(context)
        @context = context
        @transactions = {}
        @publishables = []
        @stub = create_grpc_client(context.spv)
      end

      def on_message(message)
        case message
        when Register
          @transactions[message.head_tx_hash] ||= []
          @transactions[message.head_tx_hash] << [message.encrypted_payload, message.delay]
          request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(id: 0, tx_hash: message.head_tx_hash, confirmations: 0)
          @stub.watch_tx_confirmed(request)
        when Bitcoin::Grpc::TxReceived
          head = message.tx_hash[0...32]
          cipher = RbNaCl::AEAD::ChaCha20Poly1305IETF.new(message.tx_hash.htb)
          broadcasted = @transactions[head]&.map do |transaction, delay|
            begin
              payload = cipher.decrypt("\x00" * 12, transaction.htb, '')
              tx = Bitcoin::Tx.parse_from_payload(payload)
              if delay == 0
                @context.spv.broadcast(tx)
              else
                @publishables << Publishable.new(tx, delay: message.delay)
              end
              [transaction, delay]
            rescue ::RbNaCl::CryptoError => e
            end
          end.compact
          broadcasted&.each { |t| @transactions[head].delete(t) }
          @transactions.delete(head) if @transactions[head]&.empty?
        when Bitcoin::Grpc::BlockCreated
          published = []
          @publishables.each do |publishable|
            unless publishable.block_height
              publishable.block_height = message.height
            end
            if message.height >= publishable.block_height + (publishable.delay - 1)
              @context.spv.broadcast(tx)
              published << publishable
            end
          end
          published.each do |publishable|
            @publishables.delete(publishable)
          end
        when :transactions
          @transactions
        end
      end

      def create_grpc_client(spv)
        stub = Bitcoin::Grpc::Blockchain::Stub.new(spv.build_bitcoin_grpc_url, :this_channel_is_insecure)
        requests = [
          Bitcoin::Grpc::EventsRequest.new(operation: :SUBSCRIBE, event_type: "Bitcoin::Grpc::TxReceived"),
          Bitcoin::Grpc::EventsRequest.new(operation: :SUBSCRIBE, event_type: "Bitcoin::Grpc::BlockCreated")
        ]
        stub.events(requests).each do |response|
          reference << response
        end
        stub
      end
    end
  end
end
