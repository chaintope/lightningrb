# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Negotiating < ChannelState
        def next(message, data)
          case message
          when ClosingSigned
            # TODO: verify signature.
            local_script = Bitcoin::Script.parse_from_payload(data[:local_shutdown][:scriptpubkey].htb)
            remote_script = Bitcoin::Script.parse_from_payload(data[:remote_shutdown][:scriptpubkey].htb)

            tx = Lightning::Transactions::Closing.valid_signature?(
              data[:commitments],
              local_script,
              remote_script,
              message.fee_satoshis,
              message.signature
            )
            if message.fee_satoshis == data[:closing_tx_proposed].last.local_closing_signed.fee_satoshis
              handle_mutual_close(tx, data)
            else
              fee = Lightning::Transactions::Closing.next_closing_fee(
                data[:closing_tx_proposed].last.local_closing_signed.fee_satoshis,
                message.fee_satoshis
              )
              closing = Lightning::Transactions::Closing.make_closing_tx(
                data[:commitments],
                local_script,
                remote_script,
                fee
              )
              if fee == msg[:fee_satoshis]
                handle_mutual_close(tx, store(data), closing_signed: closing.closing_signed)
              else
                data = DataNegotiating[
                  data[:commitments],
                  data[:local_shutdown],
                  data[:remote_shutdown],
                  data[:closing_tx_proposed] + [ClosingTxProposed[closing.tx, closing.closing_signed]],
                  data[:best_unpublished_closing_tx_opt]
                ]
                goto(self, data: store(data), sending: closing.closing_signed)
              end
            end
          end
        rescue InvalidCloseFee, RuntimeError => e
          puts e.backtrace
          handler_local_error(data)
        end

        def handle_mutual_close(tx, data, closing_signed: nil)
          context.blockchain << WatchConfirmed[channel, tx.txid.rhex, context.node_params.min_depth_blocks]
          context.spv.broadcast(tx)
          closing_signed = data[:closing_tx_proposed].last.local_closing_signed
          new_data = DataClosing[
            data[:commitments],
            [closing_signed],
            [tx],
            None, None, None, None, []
          ]
          goto(Closing.new(channel, context), data: new_data, sending: closing_signed)
        end

        def handler_local_error(data)
          [self, data]
        end
      end
    end
  end
end
