# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class GetChannel
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def execute(request)
          channel = context.switchboard.ask!(request)
          channel = if channel
            Lightning::Grpc::Channel.new(
              channel_id: channel[:channel_id],
              status: channel[:status],
              to_local_msat: channel[:to_local_msat],
              to_remote_msat: channel[:to_remote_msat]
            )
          else
            nil
          end
          Lightning::Grpc::GetChannelResponse.new(channel: channel)
        end
      end
    end
  end
end
