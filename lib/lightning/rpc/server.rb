# frozen_string_literal: true

require 'async'
require 'async/http/server'
require 'async/reactor'
require 'async/http/url_endpoint'
require 'async/http/response'


Async.logger.level = Logger::DEBUG

module Lightning
  module Rpc
    END_POINT = Async::HTTP::URLEndpoint.parse('http://127.0.0.1:9222')

    class Server
      def self.run(context)
        handler = lambda do |request|
          handle_request(request, context)
        end

        server = Async::HTTP::Server.new(handler, END_POINT)
        Async::Reactor.run do |task|
          task.async do
            server.run
          end
        end
      end

      def self.handle_request(request, context)
        request = JSON.parse(request.body.join)
        params = request['params']
        case request['method']
        when 'getnodeinfo'
          response = { node_id: context.node_params.node_id }.to_json
          Async::HTTP::Response[200, {}, [response]]
        when 'connect'
          node_id = params[0]
          ip = params[1]
          port = params[2] || 9735
          context.switchboard << Lightning::IO::PeerEvents::Connect[node_id, ip, port]
          Async::HTTP::Response[200, {}, []]
        when 'open'
          node_id = params[0]
          funding_satoshis = params[1]
          push_msat = params[2] || 0
          channel_flags = params[3] || 0x01
          context.switchboard << Lightning::IO::PeerEvents::OpenChannel[node_id, funding_satoshis, push_msat, channel_flags, {}]
          Async::HTTP::Response[200, {}, []]
        when 'close'
          channel_id = params[0]
          script_pubkey = params[1]
          script_pubkey = script_pubkey ? Algebrick::Some[String][script_pubkey] : Algebrick::None
          command = Lightning::Channel::Messages::CommandClose[script_pubkey]
          context.register << Lightning::Channel::Register::Forward[channel_id, command]
          Async::HTTP::Response[200, {}, []]
        when 'receive'
          payment = Lightning::Payment::Messages::ReceivePayment[params[0], params[1]]
          message = context.payment_handler.ask!(payment)
          response = { invoice: message.to_bech32 }.to_json
          Async::HTTP::Response[200, {}, [response]]
        when 'send'
          node_id = params[0]
          payment_hash = params[1]
          amount_msat = params[2]
          context.payment_initiator << Lightning::Payment::Messages::SendPayment[amount_msat, payment_hash, node_id, [], 144]
          Async::HTTP::Response[200, {}, []]
        when 'nodes'
          response = context.router.ask!(:nodes).map(&:to_json).join('')
          Async::HTTP::Response[200, {}, [response]]
        when 'channels'
          response = context.switchboard.ask!(:channels).map(&:to_json).join('')
          Async::HTTP::Response[200, {}, [response]]
        else
          Async::HTTP::Response[400, {}, ["Unsupported method. #{request['method']}"]]
        end
      rescue StandardError => e
        Async::HTTP::Response[400, {}, ["Bad Request #{e} \n #{e.backtrace}"]]
      end
    end
  end
end
