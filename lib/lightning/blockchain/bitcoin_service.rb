# frozen_string_literal: true

require 'jsonclient'

module Lightning
  module Blockchain
    class BitcoinService
      attr_reader :block_height

      def initialize(config: nil)
        @config = config
        @stub = Bitcoin::Grpc::Blockchain::Stub.new(build_bitcoin_grpc_url, :this_channel_is_insecure)
        @block_height = blockchain_info['headers']
        Thread.start do
          request = Bitcoin::Grpc::EventsRequest.new(operation: :SUBSCRIBE, event_type: "BlockCreated")
          responses = @stub.events([request])
          responses.each do |response|
            if response.block_created
              if @block_height < response.block_created.height
                @block_height = response.block_created.height
              end
            end
          end
        end
      end

      def generate_new_address(account_name)
        create_account(account_name)
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'getnewaddress',
          'params': [account_name]
        }
        client.post(url, params).body
      end

      def create_account(account_name)
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'createaccount',
          'params': [account_name]
        }
        client.post(url, params).body
      end

      def blockchain_info
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'getblockchaininfo'
        }
        client.post(url, params).body
      end

      def get_balance(account_name)
        create_account(account_name)
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'getbalance',
          'params': [account_name]
        }
        client.post(url, params).body
      end

      def list_unspent(account_name)
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'listunspentinaccount',
          'params': [account_name]
        }
        client.post(url, params).body
      end

      def sign_transaction(account_name, tx)
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'signrawtransaction',
          'params': [account_name, tx.to_payload.bth]
        }
        client.post(url, params).body
      end

      def broadcast(tx)
        client = JSONClient.new
        client.debug_dev = STDOUT
        url = build_bitcoin_rpc_url
        params = {
          'method': 'sendrawtransaction',
          'params': [tx.to_payload.bth]
        }
        client.post(url, params).body
      end

      def build_bitcoin_rpc_url
        @config ||= load_config
        @config['bitcoin']['rpc']['url']
      end

      def build_bitcoin_grpc_url
        @config ||= load_config
        @config['bitcoin']['grpc']['url']
      end

      def load_config
        file = 'config.yml'
        YAML.load_file(file)
      end
    end
  end
end
