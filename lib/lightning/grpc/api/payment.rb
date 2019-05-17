# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Payment
        attr_reader :context, :publisher

        def initialize(context, publisher)
          @context = context
          @publisher = publisher
        end

        def execute(request)
          events = []

          PaymentReceiver.spawn(:receiver, events, context, publisher, request)
          PaymentResponseEnum.new(events).each
        end

        class PaymentReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events

          def initialize(events, context, publisher, request)
            @events = events
            @context = context
            @request = request
            @publisher = publisher
            publisher << [:subscribe, Lightning::Payment::Events::PaymentSucceeded]
            context.payment_initiator << Lightning::Payment::Messages::SendPayment[request.amount_msat, request.payment_hash, request.node_id, [], 144]
          end

          def on_message(message)
            case message
            when Lightning::Payment::Events::PaymentSucceeded
              if message.payment_hash == @request.payment_hash
                events << message
                @publisher << [:unsubscribe, Lightning::Payment::Events::PaymentSucceeded]
                reference << :terminate!
              end
            end
          end
        end

        class PaymentResponseEnum
          attr_reader :events

          def initialize(events)
            @events = events
          end

          def each
            return enum_for(:each) unless block_given?
            loop do
              event = events.shift
              if event
                response = Lightning::Grpc::PaymentResponse.new
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
