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
        match message, (on ~ChannelRestored do |msg|
        end), (on ~ChannelCreated do |msg|
          @channels[msg[:temporary_channel_id]] = msg[:channel]
          @remotes[msg[:temporary_channel_id]] = msg[:remote_node_id]
        end), (on ~ChannelIdAssigned do |msg|
          @channels.delete(msg[:temporary_channel_id])
          @remotes.delete(msg[:temporary_channel_id])
          @channels[msg[:channel_id]] = msg[:channel]
          @remotes[msg[:channel_id]] = msg[:remote_node_id]
        end), (on ~ShortChannelIdAssigned do |msg|
          @short_channel_ids[msg[:short_channel_id]] = msg[:channel_id]
        end), (on ~Forward do |msg|
          channel = @channels[msg[:channel_id]]
          channel << msg[:message] if channel
        end), (on ~ForwardShortId do |msg|
          channel_id = @short_channel_ids[msg[:short_channel_id]]
          channel = @channels[channel_id]
          channel << msg[:message] if channel
        end), (on :channels do
          @channels
        end), (on :short_channel_ids do
          @short_channel_ids
        end), (on :remotes do
          @remotes
        end)
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
