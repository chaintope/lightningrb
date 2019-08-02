# frozen_string_literal: true

module Lightning
  module Utils
    # Utility for the benchmark test
    module Benchmark
      def create_btc_client(btc_setting)
        client = JSONClient.new
        client.debug_dev = STDOUT
        client.set_auth(btc_setting[:domain], btc_setting[:username], btc_setting[:password])
        [client, btc_setting[:endpoint]]
      end

      def generate_btc_address(client)
        client[0].post(client[1], {'method': 'getnewaddress'}).body["result"]
      end

      def send_to_address(client, address)
        client[0].post(client[1], {'method': 'sendtoaddress','params': [address, 10]})
      end

      def send_btc_if_needed(client, stub, local_node_id, address)
        request = Lightning::Grpc::GetBalanceRequest.new
        while stub.get_balance(request).balance < 1_000_000_000
          send_to_address(client, address)
          sleep(10)
        end
      end

      def connect(stub, remote_node_id, remote_node_ip)
        # Connect to peer
        request = Lightning::Grpc::ConnectRequest.new(
          remote_node_id: remote_node_id,
          host: remote_node_ip,
          port: 9735
        )
        responses = stub.connect(request)
        responses.each do |response|
          # wait until connected
          case
          when response.peer_connected
            break
          when response.peer_already_connected
            break
          end
        end
      end

      def get_channel(stub, remote_node_id)
        request = Lightning::Grpc::ListChannelsRequest.new(node_id: remote_node_id)
        responses = stub.list_channels(request)
        responses.channel.sort_by(&:to_local_msat).last
      end

      def get_channel_by_id(stub, channel_id)
        request = Lightning::Grpc::GetChannelRequest.new(channel_id: channel_id)
        response = stub.get_channel(request)
        response.channel
      end

      def open(stub, remote_node_id)
        request = Lightning::Grpc::OpenRequest.new(
          remote_node_id: remote_node_id,
          funding_satoshis: 10_000_000,
          push_msat: 10_000_000 * 0.1 * 1000,
          channel_flags: 0x01
        )
        responses = stub.open(request)
        channel_id = nil
        responses.each do |response|
          case
          when response.channel_id_assigned
            channel_id = response.channel_id_assigned.channel_id
          when response.channel_registered
            break
          when response.channel_updated
            break
          when response.channel_failed
            raise response.channel_failed.inspect
          end
        end
        get_channel_by_id(stub, channel_id)
      end

      def invoice(stub)
        request = Lightning::Grpc::InvoiceRequest.new(
          amount_msat: 1_000_000,
          description: 'nonsense'
        )
        stub.invoice(request)
      end

      def wait_for_route(stub, source_node_id, target_node_id, channels: [])
        short_channel_ids = channels.map { |channel| channel.short_channel_id }
        request = Lightning::Grpc::RouteRequest.new(
          source_node_id: source_node_id,
          target_node_id: target_node_id,
          short_channel_ids: short_channel_ids
        )
        responses = stub.route(request)
        responses.each do |response|
          case
          when response.route_discovered
            break
          when response.route_not_found
            sleep(30)
            return wait_for_route(stub, source_node_id, target_node_id)
          end
        end
      end

      def payment(stub, invoice, remote_node_id)
        request = Lightning::Grpc::PaymentRequest.new(
          node_id: remote_node_id,
          amount_msat: 1_000_000,
          payment_hash: invoice.payment_hash
        )
        stub.payment(request)
      end

      def wait_for_payment(responses)
        responses.each do |response|
          case
          when response.payment_succeeded
            break
          end
        end
      end

      def close(stub, channel, script_pubkey: nil)
        request = Lightning::Grpc::CloseRequest.new(
          channel_id: channel.channel_id,
          script_pubkey: script_pubkey
        )
        stub.close(request)
      end

      def wait_for_close(stub, channel_id)
        while get_channel_by_id(stub, channel_id)
          sleep(10)
        end
      end

      def increment(pb, total)
        pb.progress += 100.0/total
      end
    end
  end
end
