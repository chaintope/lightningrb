# frozen_string_literal: true

module Lightning
  module Channel
    class Channel < Concurrent::Actor::Context
      include Algebrick
      include Lightning::Channel::Events

      def initialize(channel_context)
        @context = channel_context
        @state = Lightning::Channel::ChannelState::WaitForInitInterval.new(reference, channel_context)
        @data = Algebrick::None
      end

      def on_message(message)
        log(Logger::DEBUG, "state=#{@state}")
        case message
        when :data
          return to_h(@data)
        end
        log_commitments(@data) if @data.is_a? Lightning::Channel::Messages::HasCommitments
        next_state, next_data = @state.next(message, @data)
        @state.on_transition(self, @state, @data, next_state, next_data)
        @state = next_state
        @data = next_data
        log_commitments(@data) if @data.is_a? Lightning::Channel::Messages::HasCommitments
      end

      def log_commitments(data)
        commitments = data[:commitments]
        log(Logger::DEBUG, "LocalCommit")
        log(Logger::DEBUG, "    to_local_msat:#{commitments[:local_commit][:spec][:to_local_msat]}")
        log(Logger::DEBUG, "    to_remote_msat:#{commitments[:local_commit][:spec][:to_remote_msat]}")
        log(Logger::DEBUG, "RemoteCommit")
        log(Logger::DEBUG, "    to_local_msat:#{commitments[:remote_commit][:spec][:to_local_msat]}")
        log(Logger::DEBUG, "    to_remote_msat:#{commitments[:remote_commit][:spec][:to_remote_msat]}")
        log(Logger::DEBUG, "LocalChanges")
        log(Logger::DEBUG, "    proposed:#{commitments[:local_changes][:proposed].size}")
        log(Logger::DEBUG, "    signed:  #{commitments[:local_changes][:signed].size}")
        log(Logger::DEBUG, "    acked:   #{commitments[:local_changes][:acked].size}")
        log(Logger::DEBUG, "RemoteChanges")
        log(Logger::DEBUG, "    proposed:#{commitments[:remote_changes][:proposed].size}")
        log(Logger::DEBUG, "    signed:  #{commitments[:remote_changes][:signed].size}")
        log(Logger::DEBUG, "    acked:   #{commitments[:remote_changes][:acked].size}")
      end

      def self.to_channel_id(funding_txid, funding_tx_output_index)
        # big-endian byte order
        funding_txid = funding_txid.rhex
        funding_txid[0...60].downcase +
          format(
            '%02x%02x',
            (funding_txid[60...62].to_i(16) ^ (funding_tx_output_index >> 8)) & 0xff,
            (funding_txid[62...64].to_i(16) ^ funding_tx_output_index) & 0xff
          )
      end

      def self.to_short_id(block_height, tx_index, output_index)
        ((block_height & 0xFFFFFF) << 40) | ((tx_index & 0xFFFFFF) << 16) | (output_index & 0xFFFF)
      end

      def to_h(data)
        if data.is_a? Lightning::Channel::Messages::HasCommitments
          commitments = data[:commitments]
          {
            temporary_channel_id: data.temporary_channel_id,
            channel_id: data.channel_id,
            status: data.status,
            to_local_msat: commitments[:local_commit][:spec][:to_local_msat],
            to_remote_msat: commitments[:local_commit][:spec][:to_remote_msat]
          }
        else
          {}
        end
      end
    end
  end
end
