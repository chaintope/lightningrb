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
        channels = context.channel_db.all.map { |channel_id, data| Lightning::Channel::Messages::HasCommitments.load(data.htb).first }
        channels = channels.group_by { |c| c[:commitments][:remote_param][:node_id] }
        @peers = context.peer_db.all
          .select { |node_id, peer| channels.keys.include?(node_id) }
          .inject({}) do |peers, (node_id, host, port)|
            peer = create_or_get_peer(peers, node_id, channels[node_id])
            peer << Connect[node_id, host, port, {}]
            peers[node_id] = peer
            peers
          end
      end

      def on_message(message)
        match message, (on ~Connect.(~any, any, any, any) do |connect, remote_node_id|
          unless valid_connect?(connect)
            parent << Error['cannot open connection with oneself']
          end

          peer = create_or_get_peer(peers, remote_node_id)
          peer << connect
          peers[remote_node_id] = peer
        end), (on ~OpenChannel do |open_channel|
          remote_node_id = open_channel[:remote_node_id]
          peer = peers[remote_node_id]
          if peer
            peer << open_channel
          else
            parent << Error['no connection to peer']
          end
        end), (on ~Authenticated.(any, any, ~any) do |auth, remote_node_id|
          peer = create_or_get_peer(peers, remote_node_id)
          peer << auth
          peers[remote_node_id] = peer
        end), (on :channels do
          peers.map do |node_id, peer|
            peer.ask!(:channels)
          end.flatten
        end), (on any do

        end)
      end

      def create_or_get_peer(peers, remote_node_id, initial_channels = [])
        peers[remote_node_id] || Peer.spawn(:peer, authenticator, context, remote_node_id, initial_channels)
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
