# frozen_string_literal: true

module Lightning
  module IO
    class Peer < Concurrent::Actor::Context
      include Algebrick
      include Lightning::IO::PeerEvents

      attr_accessor :status, :data

      def initialize(authenticator, context, remote_node_id)
        @status = PeerStateDisconnected.new(authenticator, context, remote_node_id)
        @data = DisconnectedData[Algebrick::None]
        context.broadcast << [:subscribe, Lightning::Channel::Events::ChannelClosed]
        context.broadcast << [:subscribe, Lightning::Channel::Events::ChannelFailed]
      end

      def on_message(message)
        log(Logger::DEBUG, "#{@status.class}, data:#{@data}, message: #{message.inspect}")
        case message
        when :channels, Lightning::Grpc::ListChannelsRequest
          return @data.channels.values.map {|channel| channel.ask!(:data) }.uniq { |channel| channel[:temporary_channel_id] }
        when Lightning::Grpc::GetChannelRequest
          return @data.channels[message.channel_id]&.ask!(:data)
        when :status
          return @status.class.name
        end
        @status, @data = @status.next(self.reference, message, @data)
      end

      class PeerState
        include Concurrent::Concern::Logging
        include Algebrick::Matching
        include Algebrick
        include Lightning::Wire::HandshakeMessages
        include Lightning::Wire::LightningMessages
        include Lightning::IO::PeerEvents
        include Lightning::Channel
        include Lightning::Channel::Events
        include Lightning::Channel::Messages

        attr_accessor :context, :remote_node_id, :authenticator, :transport

        def initialize(authenticator, context, remote_node_id, transport: nil)
          @context = context
          @remote_node_id = remote_node_id
          @authenticator = authenticator
          @transport = transport
          @retry = 0
        end
      end

      class PeerStateDisconnected < PeerState
        def next(actor, message, data)
          case message
          when Connect
            host = message[:host]
            port = message[:port]
            log(Logger::INFO, '/peer', "Connecting to #{host}:#{port}...")
            ClientSession.connect(host, port, authenticator, context.node_params.extended_private_key.priv, remote_node_id)
            [self, data.copy(address_opt: URI[host, port])]
          when Reconnect
            host = data[:address_opt][:host]
            port = data[:address_opt][:port]
            log(Logger::INFO, '/peer', "Reconnecting to #{host}:#{port}...(#{@retry})")
            ClientSession.connect(host, port, authenticator, context.node_params.extended_private_key.priv, remote_node_id)
            if @retry < 8
              Concurrent::TimerTask.new(execution_interval: 2**(@retry + 2)) do |task|
                @retry += 1
                actor << Reconnect
                task.shutdown
              end.execute
            end
            [self, data]
          when Lightning::IO::AuthenticateMessages::Authenticated
            session = message[:session]
            transport = message[:transport]
            transport << Listener[actor]
            transport << Init.new(
              globalfeatures: context.node_params.globalfeatures,
              localfeatures: context.node_params.localfeatures
            )
            [
              PeerStateInitializing.new(authenticator, context, remote_node_id, transport: transport),
              InitializingData[data[:address_opt], session, Algebrick::None],
            ]
          else
            log(Logger::WARN, '/peer@disconnected', "unhandled message: #{message.inspect}")
            [self, data]
          end
        end
      end

      class PeerStateInitializing < PeerState
        def next(actor, message, data)
          case message
          when Init
            feature = Lightning::Feature.new(message.localfeatures)
            return invalid_feature_error(message, data) unless feature.valid?
            if feature.gossip_queries?
              context.router << Lightning::Router::Messages::RequestGossipQuery.new(transport, remote_node_id)
            elsif feature.initial_routing_sync?
              context.router << Lightning::Router::Messages::InitialSync.new(transport)
            end

            log(Logger::INFO, :peer, "================================================================================")
            log(Logger::INFO, :peer, "")
            log(Logger::INFO, :peer, "PEER CONNECTED")
            log(Logger::INFO, :peer, "")
            log(Logger::INFO, :peer, "================================================================================")
            channels = initialize_stored_channels(context, remote_node_id)
            channels = channels.map do |channel_data|
              forwarder = Lightning::Channel::Forwarder.spawn(:forwarder)
              channel_context = Lightning::Channel::ChannelContext.new(context, forwarder, remote_node_id)
              channel = Lightning::Channel::Channel.spawn(:channel, channel_context)
              channel << Lightning::Channel::Messages::InputReconnected[transport, channel_data]
              [channel_data[:commitments][:channel_id], channel]
            end.to_h

            if context.node_params.ping_interval.positive?
              task = Concurrent::TimerTask.new(execution_interval: context.node_params.ping_interval, run_now: true) do
                actor << Timeout
              end
              task.execute
            end

            context.broadcast << Lightning::Io::Events::PeerConnected.new(remote_node_id: remote_node_id)

            [
              PeerStateConnected.new(authenticator, context, remote_node_id, transport: transport),
              ConnectedData[data[:address_opt], data[:session], message, channels],
            ]
          when ChannelReestablish
            task = Concurrent::TimerTask.new(execution_interval: 60, run_now: true) do
              actor << message
              task.shutdown
            end
            task.execute
            [self, data]
          when Lightning::IO::AuthenticateMessages::Unauthenticated
            context.broadcast << Lightning::Io::Events::PeerDisconnected.new(remote_node_id: remote_node_id)
            [
              PeerStateDisconnected.new(authenticator, context, remote_node_id),
              DisconnectedData[data[:address_opt]]
            ]
          else
            log(Logger::WARN, '/peer@initializing', "unhandled message: #{message.inspect}")
            [self, data]
          end
        end

        def invalid_feature_error(init, data)
          log(Logger::WARN, "received unknown even feature bits #{init.inspect}")
          # fails connection
          data[:session] << :close
          [
            PeerStateDisconnected.new(authenticator, context, remote_node_id),
            DisconnectedData[data[:address_opt]]
          ]
        end

        def initialize_stored_channels(context, remote_node_id)
          channels = context.channel_db.all.map { |channel_id, data| Lightning::Channel::Messages::HasCommitments.load(data.htb).first }

          channels.select do |channel|
            channel[:commitments][:remote_param][:node_id] == remote_node_id
          end
        end
      end

      class PeerStateConnected < PeerState
        def next(actor, message, data)
          case message
          when Timeout
            ping_size = SecureRandom.random_number(1000)
            pong_size = SecureRandom.random_number(1000)
            ping = Ping.new(num_pong_bytes: pong_size, ignored: "00" * ping_size)
            transport << ping
          when Ping
            pong_size = message.num_pong_bytes
            transport << Pong.new(ignored: "00" * pong_size) if pong_size.positive?
          when Pong
            pong_size = message.ignored.bytesize
            log(Logger::DEBUG, actor.path, "received pong with #{pong_size} bytes")
          when Lightning::IO::PeerEvents::OpenChannel
            channel, local_param = create_new_channel(context, true, message.funding_satoshis)
            temporary_channel_id = SecureRandom.hex(32)
            channel << Lightning::Channel::Messages::InputInitFunder[
              temporary_channel_id,
              message.account_name,
              message.funding_satoshis,
              message.push_msat,
              context.node_params.feerates_per_kw,
              local_param,
              transport,
              data[:remote_init],
              message.channel_flags,
              message.additional_field
            ]
            data[:channels][temporary_channel_id] = channel
          when Lightning::Wire::LightningMessages::OpenMessage
            temporary_channel_id = message.temporary_channel_id
            channel = data[:channels][temporary_channel_id]
            if channel
              log(Logger::WARN, '/peer@connected', "temporary_channel_id is duplicated. #{message.temporary_channel_id}")
            else
              channel, local_param = create_new_channel(context, false, message.funding_satoshis)
              channel << Lightning::Channel::Messages::InputInitFundee[
                temporary_channel_id, local_param, transport, data[:remote_init]
              ]
              channel << message
              data[:channels][temporary_channel_id] = channel
            end
          when HasChannelId
            channel = data[:channels][message.channel_id]
            if channel
              channel << message
            else
              # TODO : raise ERROR
            end
          when HasTemporaryChannelId
            channel = data[:channels][message.temporary_channel_id]
            if channel
              channel << message
            else
              # TODO : raise ERROR
            end
          when ChannelIdAssigned
            data[:channels][message.channel_id] = message.channel
          when Lightning::Wire::LightningMessages::GossipTimestampFilter
            data = data.copy(gossip_timestamp_filter: message)
          when Lightning::Wire::LightningMessages::GossipQuery
            context.router << Lightning::Router::Messages::QueryMessage.new(transport, remote_node_id, message)
          when RoutingMessage
            context.router << message
          when Lightning::Router::Messages::Rebroadcast
            filtered = case message[:message]
            when ChannelUpdate, NodeAnnouncement
              # SHOULD send all gossip messages whose timestamp is greater or equal to first_timestamp,
              # and less than first_timestamp plus timestamp_range.
              if data[:gossip_timestamp_filter] && !data[:gossip_timestamp_filter].match?(message[:message])
                true
              end
            end
            transport << message[:message] unless filtered
          when Lightning::IO::AuthenticateMessages::Unauthenticated
            context.broadcast << Lightning::Io::Events::PeerDisconnected.new(remote_node_id: remote_node_id)
            return [
              PeerStateDisconnected.new(authenticator, context, remote_node_id),
              DisconnectedData[data[:address_opt]]
            ]
          when Lightning::Channel::Events::ChannelClosed
            channel_id = message.channel_id
            closed_channel = data[:channels][channel_id]
            data[:channels].delete_if { |key, channel| channel == closed_channel }
          when Lightning::Channel::Events::ChannelFailed
            failed = data[:channels][message.temporary_channel_id]
            data[:channels].delete_if { |key, channel| channel == failed }
          when Connect
            context.broadcast << Lightning::Io::Events::PeerAlreadyConnected.new(remote_node_id: remote_node_id)
          else
            log(Logger::WARN, '/peer@connected', "unhandled message: #{message.inspect}, data:#{data}")
          end
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
            Bitcoin.sha256(generate_key(context.node_params, [index, 5]).priv.htb).bth,
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
