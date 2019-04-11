# frozen_string_literal: true

module Lightning
  module Channel
    class Register < Concurrent::Actor::Context
      include Lightning::Channel::Events
      include Algebrick

      def initialize(context)
        # Key: channel_id:String
        # Value: channel:Channel
        @channels = {}

        # Key: short_channel_id:String
        # Value: channel_id:Channel
        @short_channel_ids = {}

        # Key: channel_id:String
        # Value: remote_node_id:String
        @remotes = {}

        context.broadcast << [:subscribe, ChannelCreated]
        context.broadcast << [:subscribe, ChannelRestored]
        context.broadcast << [:subscribe, ChannelIdAssigned]
        context.broadcast << [:subscribe, ShortChannelIdAssigned]
      end

      def on_message(message)
        log(Logger::INFO, message)
        case message
        when ChannelRestored
          @channels[message.channel_id] = message.channel
          @remotes[message.channel_id] = message.remote_node_id
        when ChannelCreated
          @channels[message.temporary_channel_id] = message.channel
          @remotes[message.temporary_channel_id] = message.remote_node_id
        when ChannelIdAssigned
          @channels.delete(message.temporary_channel_id)
          @remotes.delete(message.temporary_channel_id)
          @channels[message.channel_id] = message.channel
          @remotes[message.channel_id] = message.remote_node_id
        when ShortChannelIdAssigned
          @short_channel_ids[message.short_channel_id] = message.channel_id
        when Forward
          channel = @channels[message.channel_id]
          channel << message.message if channel
        when ForwardShortId
          channel_id = @short_channel_ids[message.short_channel_id]
          channel = @channels[channel_id]
          channel << message.message if channel
        when :channels
          @channels
        when :short_channel_ids
          @short_channel_ids
        when :remotes
          @remotes
        end
      end

      Forward = Algebrick.type do
        fields! channel_id: String, message: Object
      end

      ForwardShortId = Algebrick.type do
        fields! short_channel_id: Numeric, message: Object
      end
    end
  end
end
