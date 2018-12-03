# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      include Concurrent::Concern::Logging
      include Algebrick
      include Algebrick::Matching
      include Lightning::Channel
      include Lightning::Channel::Events
      include Lightning::Channel::Messages
      include Lightning::Transactions
      include Lightning::Wire::LightningMessages
      include Lightning::Blockchain::Messages
      include Lightning::Exceptions

      autoload :Closed, 'lightning/channel/channel_state/closed'
      autoload :Closing , 'lightning/channel/channel_state/closing'
      autoload :Error , 'lightning/channel/channel_state/error'
      autoload :Negotiating, 'lightning/channel/channel_state/negotiating'
      autoload :Normal, 'lightning/channel/channel_state/normal'
      autoload :Offline, 'lightning/channel/channel_state/offline'
      autoload :Shutdowning, 'lightning/channel/channel_state/shutdowning'
      autoload :Syncing, 'lightning/channel/channel_state/syncing'
      autoload :WaitForAcceptChannel, 'lightning/channel/channel_state/wait_for_accept_channel'
      autoload :WaitForFundingConfirmed, 'lightning/channel/channel_state/wait_for_funding_confirmed'
      autoload :WaitForFundingCreated, 'lightning/channel/channel_state/wait_for_funding_created'
      autoload :WaitForFundingInternal, 'lightning/channel/channel_state/wait_for_funding_internal'
      autoload :WaitForFundingLocked, 'lightning/channel/channel_state/wait_for_funding_locked'
      autoload :WaitForFundingSigned, 'lightning/channel/channel_state/wait_for_funding_signed'
      autoload :WaitForInitInterval, 'lightning/channel/channel_state/wait_for_init_interval'
      autoload :WaitForOpenChannel, 'lightning/channel/channel_state/wait_for_open_channel'

      attr_accessor :channel, :context

      def initialize(channel, context)
        @channel = channel
        @context = context
      end

      def goto(new_state, data: nil, sending: nil)
        send_to_forwarder(sending)
        @data = data
        [new_state, @data]
      end

      def closed?
        is_a? Lightning::Channel::ChannelState::Closed
      end

      def store(data)
        context.channel_db.insert_or_update(data)
        data
      end

      def on_transition(channel, state, data, next_state, next_data)
        if state != next_state
          context.broadcast << ChannelStateChanged[
            channel.reference, channel.reference.parent, context.remote_node_id, state, next_state, next_data
          ]
        end
        Concurrent::ScheduledTask.execute(10) { channel << :shutdown } if next_state.closed?

        if keep_channel_state?(data, next_data)
          # Do nothing
        elsif next_data.is_a? Lightning::Channel::Messages::DataNormal
          context.broadcast << LocalChannelUpdate[
            channel.reference, next_data.channel_id, next_data[:short_channel_id], next_data[:commitments][:remote_param][:node_id], next_data[:channel_announcement], next_data[:channel_update]
          ]
        elsif data.is_a? Lightning::Channel::Messages::DataNormal
          context.broadcast << LocalChannelDown[
            channel.reference, data.channel_id, data[:short_channel_id], data[:commitments][:remote_param][:node_id]
          ]
        end
      end

      def keep_channel_state?(data, next_data)
        data.is_a?(Lightning::Channel::Messages::DataNormal) &&
        next_data.is_a?(Lightning::Channel::Messages::DataNormal) &&
        data[:channel_update] == next_data[:channel_update] &&
        data[:channel_announcement] == next_data[:channel_announcement]
      end

      private

      def send_to_forwarder(messages)
        return unless messages
        messages = [messages] unless messages.is_a? Array
        messages.each do |message|
          context.forwarder << message
        end
      end
    end
  end
end
