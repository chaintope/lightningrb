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
        match message, (on WatchConfirmed.(~any, ~any, ~any) do |listener, tx_hash, blocks|
          Thread.start(listener) do |listener|
            id = SecureRandom.random_number(1 << 32)
            request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(id: id, tx_hash: tx_hash, confirmations: 3)
            response = stub.watch_tx_confirmed(request)
            response.each do |r|
              listener << Lightning::Blockchain::Messages::WatchEventConfirmed["confirmed", r.confirmed.block_height, r.confirmed.tx_index]
              break
            end
          end

          Thread.start(listener) do |listener|
            id = SecureRandom.random_number(1 << 32)
            request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(id: id, tx_hash: tx_hash, confirmations: 6)
            response = stub.watch_tx_confirmed(request)
            response.each do |r|
              listener << Lightning::Blockchain::Messages::WatchEventConfirmed["deeply_confirmed", r.confirmed.block_height, r.confirmed.tx_index]
              break
            end
          end
        end)
      end
    end
  end
end
