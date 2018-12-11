# frozen_string_literal: true

module Lightning
  module Blockchain
    class Watcher < Concurrent::Actor::Context
      include Concurrent::Concern::Logging
      include Algebrick::Matching
      include Lightning::Blockchain::Messages

      attr_reader :watchings, :stub
      def initialize
        @watchings = []
        @stub = Bitcoin::Grpc::Blockchain::Stub.new('localhost:8080', :this_channel_is_insecure)
      end

      def on_message(message)
        match message, (on WatchConfirmed.(~any, ~any, ~any) do |listener, tx_hash, blocks|
          request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(tx_hash: tx_hash, confirmations: 3)
          response = stub.watch_tx_confirmed(request)
          Thread.start(response, listener) do |response, listener|
            response.each do |r|
              listener << WatchEventConfirmed["confirmed", r.confirmed.block_height, r.confirmed.tx_index]
              break
            end
          end

          request = Bitcoin::Grpc::WatchTxConfirmedRequest.new(tx_hash: tx_hash, confirmations: 6)
          response = stub.watch_tx_confirmed(request)
          Thread.start(response, listener) do |response, listener|
            response.each do |r|
              listener << WatchEventConfirmed["deeply_confirmed", r.confirmed.block_height, r.confirmed.tx_index]
              break
            end
          end
        end), (on :watchings do
          watchings
        end)
      end
    end
  end
end
