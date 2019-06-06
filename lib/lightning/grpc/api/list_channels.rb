# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class ListChannels
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def execute(request)
          channel = context.switchboard.ask!(request)
          channel = channel.map do |c|
            Lightning::Grpc::Channel.new(
              channel_id: c[:channel_id],
              status: c[:status],
              to_local_msat: c[:to_local_msat],
              to_remote_msat: c[:to_remote_msat],
              local_node_id: c[:local_node_id],
              remote_node_id: c[:remote_node_id]
            )
          end
          Lightning::Grpc::ListChannelsResponse.new(channel: channel)
        end
      end
    end
  end
end
