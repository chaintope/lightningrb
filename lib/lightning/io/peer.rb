# frozen_string_literal: true

module Lightning
  module IO
    class Peer < Concurrent::Actor::Context
      include Algebrick
      include Lightning::IO::PeerEvents

      def initialize(authenticator, context, remote_node_id)
        @status = PeerStateDisconnected.new(self, authenticator, context, remote_node_id)
        channels = context.channel_db.all.map { |channel_id, data| Lightning::Channel::Messages::HasCommitments.load(data.htb).first }
        # channels = channels.group_by { |c| c[:commitments][:remote_param][:node_id] }
        channels.map do |channel_data|
          forwarder = Lightning::Channel::Forwarder.spawn(:forwarder)
          channel_context = Lightning::Channel::ChannelContext.new(context, forwarder, remote_node_id)
          channel = Lightning::Channel::Channel.spawn(:channel, channel_context)
          channel << Lightning::Channel::Messages::InputRestored[channel_data]
          channel
        end

        @data = DisconnectedData[Algebrick::None, channels]
      end

      def on_message(message)
        log(Logger::DEBUG, "#{@status}, message: #{message}")
        match message, (on :channels do
          log(Logger::DEBUG, "#{@status}, channels: #{@status.channels}")
          return @status.channels.values.map {|channel| channel.ask!(:data) }
        end), (on any do
        end)
        @status, @data = @status.next(message, @data)
      end

      class PeerState
        include Concurrent::Concern::Logging
        include Algebrick::Matching
        include Algebrick
        include Lightning::IO::AuthenticateMessages
        include Lightning::Wire::HandshakeMessages
        include Lightning::Wire::LightningMessages
        include Lightning::IO::PeerEvents
        include Lightning::Channel
        include Lightning::Channel::Events
        include Lightning::Channel::Messages

        attr_accessor :actor, :context, :remote_node_id, :authenticator, :transport, :channels, :db

        def initialize(actor, authenticator, context, remote_node_id, transport: nil)
          @actor = actor
          @context = context
          @remote_node_id = remote_node_id
          @authenticator = authenticator
          @transport = transport
          @channels = {}
          @db = context.peer_db
        end
      end

      class PeerStateDisconnected < PeerState
        def next(message, data)
          match [message, data], (on Array.(Connect.(~any, ~any, ~any, any), DisconnectedData) do |remote_node_id, host, port|
            Client.connect(host, port, authenticator, context.node_params.extended_private_key.priv, remote_node_id)
            [self, data]
          end), (on Array.(Authenticated.(~any, ~any, ~any), DisconnectedData.(any, ~any)) do |conn, transport, node_id, channels|
            transport << Listener[actor, conn]
            transport << Init[0, '', 1, '08'.htb]
            outgoing = conn.is_a?(Lightning::IO::ClientConnection)
            db.insert_or_update(node_id, conn.host, conn.port) if outgoing
            [
              PeerStateInitializing.new(actor, authenticator, context, remote_node_id, transport: transport),
              InitializingData[outgoing ? URI[conn.host, conn.port] : Algebrick::None, transport, channels, Algebrick::None],
            ]
          end), (on any do
            log(Logger::WARN, '/peer@disconnected', "unhandled message: #{message}")
            [self, data]
          end)
        end
      end

      class PeerStateInitializing < PeerState
        def next(message, data)
          match [message, data], (on Array.(~Init, InitializingData.(~any, ~any, ~any, any)) do |remote_init, address_opt, transport, initial_channels|
            log(Logger::INFO, :peer, "================================================================================")
            log(Logger::INFO, :peer, "")
            log(Logger::INFO, :peer, "PEER CONNECTED")
            log(Logger::INFO, :peer, "")
            log(Logger::INFO, :peer, "================================================================================")
            initial_channels.each do |channel_id, channel|
              channel << Lightning::Channel::Messages::InputReconnected[transport]
              channels[channel_id] = channel
            end
            [
              PeerStateConnected.new(actor, authenticator, context, remote_node_id, transport: transport),
              ConnectedData[address_opt, transport, remote_init, channels],
            ]
          end), (on Array.(~ChannelReestablish, ~InitializingData) do |msg, data|
            task = Concurrent::TimerTask.new(execution_interval: 60, run_now: true) do
              actor << msg
              task.shutdown
            end
            task.execute
            [self, data]
          end), (on any do
            log(Logger::WARN, '/peer@initializing', "unhandled message: #{message}")
            [self, data]
          end)
        endlib/lightning/channel/channel_context.rb
      end

      class PeerStateConnected < PeerState
        def initialize(actor, authenticator, context, remote_node_id, transport: nil)
          super
          return unless context.node_params.ping_interval.positive?
          task = Concurrent::TimerTask.new(execution_interval: context.node_params.ping_interval, run_now: true) do
            actor << Timeout
          end
          task.execute
        end

        def next(message, data)
          match [message, data], (on Array.(Timeout, ConnectedData) do
            ping_size = SecureRandom.random_number(1000)
            pong_size = SecureRandom.random_number(1000)
            ping = Ping[num_pong_bytes: pong_size, byteslen: ping_size, ignored: "\x00" * ping_size]
            transport << ping
          end), (on Array.(Ping.(~any, any, any), ConnectedData) do |pong_size|
            transport << Pong[byteslen: pong_size, ignored: "\x00" * pong_size] if pong_size.positive?
          end), (on Array.(Pong.(~any, any), any) do |pong_size|
            log(Logger::DEBUG, actor.path, "received pong with #{pong_size} bytes")
          end), (on Array.(~PeerEvents::OpenChannel, ConnectedData.(any, any, ~any, any)) do |open_channel, remote_init|
            channel, local_param = create_new_channel(context, true, open_channel[:funding_satoshis])
            temporary_channel_id = SecureRandom.hex(32)
            channel << Lightning::Channel::Messages::InputInitFunder[
              temporary_channel_id,
              open_channel[:funding_satoshis],
              open_channel[:push_msat],
              context.node_params.feerates_per_kw,
              local_param,
              transport,
              remote_init,
              open_channel[:channel_flags]
            ]
            channels[temporary_channel_id] = channel
          end), (on Array.(~Lightning::Channel::Messages::OpenChannel, ConnectedData.(any, any, ~any, any)) do |open_channel, remote_init|
            temporary_channel_id = open_channel[:temporary_channel_id]
            channel = channels[temporary_channel_id]
            if channel
              log(Logger::WARN, '/peer@connected', "temporary_channel_id is duplicated. #{open_channel.temporary_channel_id}")
            else
              channel, local_param = create_new_channel(context, false, open_channel[:funding_satoshis])
              channel << Lightning::Channel::Messages::InputInitFundee[
                temporary_channel_id, local_param, @transport, remote_init
              ]
              channel << open_channel
              channels[temporary_channel_id] = channel
            end
          end), (on Array.(~HasChannelId, ~ConnectedData) do |msg, _data|
            channel = channels[msg[:channel_id]]
            if channel
              channel << msg
            else
              # TODO : raise ERROR
            end
          end), (on Array.(~HasTemporaryChannelId, ~ConnectedData) do |msg, _data|
            channel = channels[msg[:temporary_channel_id]]
            if channel
              channel << msg
            else
              # TODO : raise ERROR
            end
          end), (on Array.(ChannelIdAssigned.(~any, any, ~any, ~any), ConnectedData) do |channel, temporary_channel_id, channel_id|
            channels[channel_id] = channel
          end), (on Array.(~RoutingMessage, ~ConnectedData) do |msg, _data|
            context.router << msg
          end)  , (on any do
            log(Logger::WARN, '/peer@connected', "unhandled message: #{message}, data:#{data}")
          end)
          [self, data]
        end

        private

        def create_new_channel(context, funder, funding_satoshis)
          default_final_script_pubkey = Helpers.final_script_pubkey(context)
          local_param = make_channel_params(context, default_final_script_pubkey, funder, funding_satoshis)
          forwarder = Forwarder.spawn(:forwarder)
          channel_context = ChannelContext.new(context, forwarder, remote_node_id)
          channel = ::Lightning::Channel::Channel.spawn(:channel, channel_context)
          [channel, local_param]
        end

        def make_channel_params(context, script_pubkey, funder, funding_satoshis)
          index = SecureRandom.random_number(2**64)
          LocalParam[
            context.node_params.node_id,
            context.node_params.dust_limit_satoshis,
            context.node_params.max_htlc_value_in_flight_msat,
            context.node_params.reserve_to_funding_ratio * funding_satoshis,
            context.node_params.htlc_minimum_msat,
            context.node_params.delay_blocks,
            context.node_params.max_accepted_htlcs,
            generate_key(context.node_params, [index, 0]).key,
            generate_key(context.node_params, [index, 1]).priv.to_i(16),
            generate_key(context.node_params, [index, 2]).priv.to_i(16),
            generate_key(context.node_params, [index, 3]).priv.to_i(16),
            generate_key(context.node_params, [index, 4]).priv.to_i(16),
            script_pubkey,
            Bitcoin.sha256(generate_key(context.node_params, [index, 5]).priv.htb),
            funder ? 1 : 0,
            context.node_params.globalfeatures,
            context.node_params.localfeatures
          ]
        end

        def generate_key(node_params, paths)
          paths.inject(node_params.extended_private_key) { |key, path| key.derive(path) }
        end
      end
    end
  end
end
