# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Route
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def execute(request)
          events = []

          RouteReceiver.spawn(:receiver, events, context, request)
          RouteResponseEnum.new(events).each
        end

        class RouteReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events

          def initialize(events, context, request)
            @events = events
            @context = context
            @request = request
            context.router << Lightning::Router::Messages::RouteRequest[@request.source_node_id, @request.target_node_id, []]
          end

          def on_message(message)
            case message
            when Lightning::Router::Messages::RouteResponse
              routing_info = message.hops.map do |hop|
                Lightning::Router::Messages::RoutingInfo.new(
                  pubkey: hop[:node_id],
                  short_channel_id: hop[:last_update][:short_channel_id],
                  fee_base_msat: hop[:last_update][:fee_base_msat],
                  fee_proportional_millionths: hop[:last_update][:fee_proportional_millionths],
                  cltv_expiry_delta: hop[:last_update][:cltv_expiry_delta],
                )
              end
              events << Lightning::Router::Messages::RouteDiscovered.new(routing_info: routing_info)
              reference << :terminate!
            when :route_not_found
              events << Lightning::Router::Messages::RouteNotFound.new(
                source_node_id: @request.source_node_id, target_node_id: @request.target_node_id
              )
            end
          end
        end

        class RouteResponseEnum
          attr_reader :events

          def initialize(events)
            @events = events
          end

          def each
            return enum_for(:each) unless block_given?
            loop do
              event = events.shift
              if event
                response = Lightning::Grpc::RouteResponse.new
                field = event.class.name.split('::').last.snake
                response[field] = event
                yield response
              else
                sleep(1)
              end
            end
          end
        end
      end
    end
  end
end
