# frozen_string_literal: true

module Lightning
  module IO
    class Switchboard < Concurrent::Actor::Context
      include Algebrick::Matching
      include Lightning::Wire::LightningMessages
      include Lightning::IO::AuthenticateMessages
      include Lightning::IO::PeerEvents

      attr_accessor :context, :peers, :authenticator

      def initialize(authenticator, context)
        @context = context
        @authenticator = authenticator
        @authenticator << InitializingAuth[self]
        load_peers
      end

      def load_peers
        @peers = context.peer_db.connected
          .inject({}) do |peers, (node_id, host, port, connected)|
            peer = create_or_get_peer(peers, node_id)
            peer << Connect[node_id, host, port, {}]
            peers[node_id] = peer
            peers
          end
      end

      def on_message(message)
        match message, (on ~Connect.(~any, ~any, ~any, any) do |connect, remote_node_id, host, port|
          unless valid_connect?(connect)
            parent << Error['cannot open connection with oneself']
          end

          peer = create_or_get_peer(peers, remote_node_id)
          peer << connect

          context.peer_db.insert_or_update(remote_node_id, host: host, port: port)
          peers[remote_node_id] = peer
        end), (on ~OpenChannel do |open_channel|
          remote_node_id = open_channel[:remote_node_id]
          peer = peers[remote_node_id]
          if peer
            peer << open_channel
          else
            parent << Error.new(data: 'no connection to peer')
          end
        end), (on ~Authenticated.(~any, any, ~any) do |auth, conn, remote_node_id|
          peer = create_or_get_peer(peers, remote_node_id)
          peer << auth

          context.peer_db.update(remote_node_id, connected: 1)

          peers[remote_node_id] = peer
        end), (on :channels do
          peers.map do |node_id, peer|
            peer.ask!(:channels)
          end.flatten
        end), (on :peers do
          peers
        end), (on Lightning::Router::Messages::Data do
          peers.each do |node_id, peer|
            # nodes : key is public key(String)
            #         value is NodeAnnouncement
            # channels: key is short channel id (Numeric)
            #           value is ChannelAnnouncement
            # updates : key is ChannelDesc
            #           value is ChannelUpdate
            message[:nodes].each do |public_key, node_announcement|
              peer << Lightning::Router::Messages::Rebroadcast[node_announcement]
            end
            message[:channels].each do |short_channel_id, channel_announcement|
              peer << Lightning::Router::Messages::Rebroadcast[channel_announcement]
            end
            message[:updates].each do |channel_desc, channel_update|
              peer << Lightning::Router::Messages::Rebroadcast[channel_update]
            end
          end
        end), (on Unauthenticated do
            remote_node_id = message[:remote_node_id] if message[:remote_node_id].is_a? String
            if remote_node_id && peers[remote_node_id]
              peers[remote_node_id] << Unauthenticated[remote_node_id]
              peers[remote_node_id] << Reconnect
            end
        end), (on any do

        end)
      end

      def create_or_get_peer(peers, remote_node_id)
        peers[remote_node_id] || Peer.spawn("peer[#{remote_node_id}]", authenticator, context, remote_node_id)
      end

      def valid_connect?(connect)
        true
      end

      def inspect
        '#<Lightning::IO::Switchboard>'
      end
    end
  end
end
