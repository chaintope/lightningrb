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
        case message
        when :data
          return to_h(@data)
        end
        next_state, next_data = @state.next(message, @data)
        @state.on_transition(self, @state, @data, next_state, next_data)
        @state = next_state
        @data = next_data
      rescue => e
        log(Logger::ERROR, "channel failed")
        log(Logger::ERROR, e.message)
        log(Logger::ERROR, e.backtrace)
        reference << :terminate! unless reference.ask!(:terminated?)
      ensure
        log_commitments(@data) if @data.is_a? Lightning::Channel::Messages::HasCommitments
      end

      def log_commitments(data)
        commitments = data[:commitments]
        log(Logger::INFO, "channel_id:     #{data.channel_id}")
        log(Logger::INFO, "local_node_id:  #{commitments[:local_param][:node_id]}")
        log(Logger::INFO, "remote_node_id: #{commitments[:remote_param][:node_id]}")
        log(Logger::INFO, "LocalCommit")
        log(Logger::INFO, "    htlcs:  #{commitments[:local_commit][:spec][:htlcs].size}")
        log(Logger::INFO, "    to_local_msat:  #{commitments[:local_commit][:spec][:to_local_msat]}")
        log(Logger::INFO, "    to_remote_msat: #{commitments[:local_commit][:spec][:to_remote_msat]}")
        log(Logger::INFO, "RemoteCommit")
        log(Logger::INFO, "    htlcs:  #{commitments[:remote_commit][:spec][:htlcs].size}")
        log(Logger::INFO, "    to_local_msat:  #{commitments[:remote_commit][:spec][:to_local_msat]}")
        log(Logger::INFO, "    to_remote_msat: #{commitments[:remote_commit][:spec][:to_remote_msat]}")
        log(Logger::INFO, "LocalChanges")
        log(Logger::INFO, "    proposed:#{commitments[:local_changes][:proposed].size}")
        log(Logger::INFO, "    signed:  #{commitments[:local_changes][:signed].size}")
        log(Logger::INFO, "    acked:   #{commitments[:local_changes][:acked].size}")
        log(Logger::INFO, "RemoteChanges")
        log(Logger::INFO, "    proposed:#{commitments[:remote_changes][:proposed].size}")
        log(Logger::INFO, "    signed:  #{commitments[:remote_changes][:signed].size}")
        log(Logger::INFO, "    acked:   #{commitments[:remote_changes][:acked].size}")
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
            temporary_channel_id: data.respond_to?(:temporary_channel_id) ? data.temporary_channel_id  : '',
            channel_id: data.channel_id,
            status: data.status,
            short_channel_id: data.respond_to?(:short_channel_id) ? data.short_channel_id : '',
            to_local_msat: commitments[:local_commit][:spec][:to_local_msat],
            to_remote_msat: commitments[:local_commit][:spec][:to_remote_msat],
            local_node_id: commitments[:local_param][:node_id],
            remote_node_id: commitments[:remote_param][:node_id]
          }
        else
          {}
        end
      end
    end
  end
end
