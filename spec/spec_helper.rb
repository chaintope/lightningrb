# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'lightning'
require 'factory_bot'
require 'support/factory_bot'

def test_wallet_path(wallet_id: 1)
  default_path = Dir.tmpdir + '/wallet'
  "#{default_path}wallet#{wallet_id}/"
end

def create_test_wallet(wallet_id: 1)
  path = test_wallet_path(wallet_id: wallet_id)
  FileUtils.rm_r(path) if Dir.exist?(path)

  default_path = Dir.tmpdir + '/wallet'
  Bitcoin::Wallet::Base.create(wallet_id, default_path)
end

def create_test_spv
  block = double('block')
  allow(block).to receive(:height).and_return(101)

  chain = double('chain')
  allow(chain).to receive(:latest_block).and_return(block)

  spv = double('spv')
  allow(spv).to receive(:chain).and_return(chain)
  allow(spv).to receive(:broadcast).and_return(nil)
  allow(spv).to receive(:add_observer).and_return(nil)
  spv
end

class DummyActor < Concurrent::Actor::Context
  def on_message(message)
  end
end

class DummyRelayer < Concurrent::Actor::Context
  def on_message(message)
    if message.is_a? Array
      message[0] << message[1]
    end
  end
end

def spawn_dummy_actor(name: :dummy)
  DummyActor.spawn(name)
end

def spawn_dummy_relayer(name: :dummy_relayer)
  DummyRelayer.spawn(name)
end
