# frozen_string_literal: true

module Lightning
  class Context
    attr_accessor :node_params, :wallet, :spv, :blockchain, :router, :relayer, :broadcast, :register, :payment_handler
    attr_accessor :payment_initiator, :watch_tower
    attr_accessor :switchboard
    attr_accessor :node_db, :peer_db, :channel_db

    def initialize(spv)
      @node_params = Lightning::NodeParams.new
      @wallet = Lightning::Blockchain::Wallet.new(spv, self)
      @spv = spv
      @blockchain = Lightning::Blockchain::Watcher.spawn(:watcher, spv)
      @broadcast = Lightning::IO::Broadcast.spawn(:broadcast)
      @watch_tower = Lightning::Blockchain::WatchTower.spawn(:watch_tower, self)

      @node_db = Lightning::Store::NodeDb.new("tmp/node_db")
      @peer_db = Lightning::Store::PeerDb.new('tmp/peer_db')
      @channel_db = Lightning::Store::ChannelDb.new('tmp/channel_db')

      @router = Lightning::Router::Router.spawn(:router, self)
      @relayer = Lightning::Payment::Relayer.spawn(:relayer, self)
      @register = Lightning::Channel::Register.spawn(:register, self)
      @payment_handler = Lightning::Payment::PaymentHandler.spawn(:payment_handler, self)
      @payment_initiator = Lightning::Payment::PaymentInitiator.spawn(:payment_initiator, node_params.node_id, self)
    end
  end
end
