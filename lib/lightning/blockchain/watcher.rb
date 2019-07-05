# frozen_string_literal: true

module Lightning
  module Blockchain
    class Watcher < Concurrent::Actor::Context
      include Concurrent::Concern::Logging
      include Algebrick::Matching
      include Lightning::Blockchain::Messages

      attr_reader :stub
      def initialize(spv)
        @stub = Bitcoin::Grpc::Blockchain::Stub.new(spv.build_bitcoin_grpc_url, :this_channel_is_insecure)
      end

      def on_message(message)
        case message
        when WatchConfirmed
          Thread.start(message[:listener]) do |listener|
            id = SecureRandom.random_number(1 << 32)
            request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(id: id, tx_hash: message[:tx_hash], confirmations: 3)
            response = stub.watch_tx_confirmed(request)
            response.each do |r|
              log(Logger::INFO, :watcher, "RECEIVE WatchEventConfirmed event.#{r}")
              listener << Lightning::Blockchain::Messages::WatchEventConfirmed["confirmed", r.confirmed.block_height, r.confirmed.tx_index]
              break
            end
          end

          Thread.start(message[:listener]) do |listener|
            id = SecureRandom.random_number(1 << 32)
            request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(id: id, tx_hash:  message[:tx_hash], confirmations: 6)
            response = stub.watch_tx_confirmed(request)
            response.each do |r|
              log(Logger::INFO, :watcher, "RECEIVE WatchEventConfirmed event.#{r}")
              listener << Lightning::Blockchain::Messages::WatchEventConfirmed["deeply_confirmed", r.confirmed.block_height, r.confirmed.tx_index]
              break
            end
          end
        else
          handle_unsupported_message(message)
        end
      end

      def handle_unsupported_message(message)
        log(Logger::WARN, :watcher, "unsupported mesage:#{message}")
      end
    end
  end
end
