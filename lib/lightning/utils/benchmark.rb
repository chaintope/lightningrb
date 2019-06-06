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

      def send_to_address(client, address)
        client[0].post(client[1], {'method': 'sendtoaddress','params': [address, 10]})
      end

      def generate(client)
        sleep(2)
        client[0].post(client[1], {'method': 'generate','params': [1]})
        sleep(1)
      end

      def send_btc_if_needed(client, rpc, local_node_id)
        address = rpc.generate_new_address(local_node_id)

        while rpc.get_balance(local_node_id) < 1_000_000_000
          send_to_address(client, address)
          generate(client)
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

      def open(client, stub, remote_node_id)
        request = Lightning::Grpc::OpenRequest.new(
          remote_node_id: remote_node_id,
          funding_satoshis: 10_000_000,
          push_msat: 10_000_000 * 0.1 * 1000,
          channel_flags: 0x01
        )
        responses = stub.open(request)
        responses.each do |response|
          case
          when response.channel_id_assigned
            4.times do
              generate(client)
            end
          when response.short_channel_id_assigned
            4.times do
              generate(client)
            end
          when response.channel_registered
            break
          when response.channel_updated
            break
          end
        end
      end

      def invoice(stub)
        request = Lightning::Grpc::InvoiceRequest.new(
          amount_msat: 1_000_000,
          description: 'nonsense'
        )
        stub.invoice(request)
      end

      def wait_for_route(client, stub, source_node_id, target_node_id)
        request = Lightning::Grpc::RouteRequest.new(
          source_node_id: source_node_id,
          target_node_id: target_node_id
        )
        responses = stub.route(request)
        responses.each do |response|
          case
          when response.route_discovered
            break
          when response.route_not_found
            generate(client)
            sleep(30)
            return wait_for_route(client, stub, source_node_id, target_node_id)
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

      def increment(pb, total)
        pb.progress += 100.0/total
      end
    end
  end
end
