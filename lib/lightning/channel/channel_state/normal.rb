# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Normal < ChannelState
        def next(message, data)
          case message
          when CommandAddHtlc
            return handle_command_error("error", data) if data.shutting_down?
            new_commitments, new_message = Commitment.send_add(data[:commitments], message, origin(message), context.spv)
            return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
            channel << CommandSignature if message[:commit]
            return goto(self, data: data.copy(commitments: new_commitments), sending: new_message)
          when UpdateAddHtlc
            new_commitments = Commitment.receive_add(data[:commitments], message, context.spv)
            return handle_local_error(new_commitments, data) unless new_commitments.is_a? Commitments
            return goto(self, data: data.copy(commitments: new_commitments))
          when CommandFulfillHtlc
            new_commitments, new_message = Commitment.send_fulfill(data[:commitments], message)
            return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
            channel << CommandSignature if message[:commit]
            return goto(self, data: data.copy(commitments: new_commitments), sending: new_message)
          when UpdateFulfillHtlc
            new_commitments, origin, htlc = Commitment.receive_fulfill(data[:commitments], message)
            case new_commitments
            when Commitments
              context.relayer << Lightning::Payment::Relayer::ForwardFulfill[message, origin, htlc]
              return goto(self, data: data.copy(commitments: new_commitments))
            else
              [self, data]
            end
          when CommandFailHtlc
            new_commitments, new_message = Commitment.send_fail(data[:commitments], message, context.node_params.private_key)
            return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
            channel << CommandSignature if message[:commit]
            return goto(self, data: data.copy(commitments: new_commitments), sending: new_message)
          when UpdateFailHtlc
            new_commitments, origin, htlc = Commitment.receive_fail(data[:commitments], message)
            case new_commitments
            when Commitments
              context.relayer << Lightning::Payment::Relayer::ForwardFail[message, origin, htlc]
              return goto(self, data: data.copy(commitments: new_commitments))
            else
              [self, data]
            end
          when CommandFailMalformedHtlc
            new_commitments, new_message = Commitment.send_fail_malformed(data[:commitments], message)
            return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
            channel << CommandSignature if message[:commit]
            return goto(self, data: data.copy(commitments: new_commitments), sending: new_message)
          when UpdateFailMalformedHtlc
            new_commitments, origin, htlc = Commitment.receive_fail_malformed(data[:commitments], message)
            case new_commitments
            when Commitments
              context.relayer << Lightning::Payment::Relayer::ForwardFailMalformed[message, origin, htlc]
              return goto(self, data: data.copy(commitments: new_commitments))
            else
              [self, data]
            end
          when CommandUpdateFee
            new_commitments, new_message = Commitment.send_fee(data[:commitments], message)
            return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
            channel << CommandSignature if message[:commit]
            return goto(self, data: data.copy(commitments: new_commitments), sending: new_message)
          when UpdateFee
            new_commitments, origin, htlc = Commitment.receive_fee(data[:commitments], message, context.node_params)
            case new_commitments
            when Commitments
              return goto(self, data: data.copy(commitments: new_commitments))
            else
              [self, data]
            end
          when CommandSignature
            case data[:commitments][:remote_next_commit_info]
            when WaitingForRevocation
              wait = data[:commitments][:remote_next_commit_info]
              wait1 = WaitingForRevocation[
                wait[:next_remote_commit],
                wait[:sent],
                wait[:sent_after_local_commit_index],
                true
              ]
              new_commitments = data[:commitments].copy(remote_next_commit_info: wait1)
              return goto(self, data: data.copy(commitments: new_commitments))
            else
              return [self, data] unless Commitment.local_has_changes?(data[:commitments])
              new_commitments, new_message = Commitment.send_commit(data[:commitments])
              return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
              new_commitments[:local_changes][:signed].each do |change|
                context.relayer << CommandAck[change.channel_id, change.id] if change.is_a?(UpdateFulfillHtlc)
              end
              return goto(self, data: store(data.copy(commitments: new_commitments)), sending: new_message)
            end
          when CommitmentSigned
            new_commitments, new_message = Commitment.receive_commit(data[:commitments], message)
            return handle_command_error(new_commitments, data) unless new_commitments.is_a? Commitments
            channel << CommandSignature if Commitment.local_has_changes?(new_commitments)
            context.broadcast << ChannelSignatureReceived.build(channel)
            return goto(self, data: store(data.copy(commitments: new_commitments)), sending: new_message)
          when RevokeAndAck
            new_commitments = Commitment.receive_revocation(data[:commitments], message)
            return handle_local_error(new_commitments, data) unless new_commitments.is_a? Commitments
            data[:commitments][:remote_changes][:signed].each do |change|
              context.relayer << Lightning::Payment::Relayer::ForwardAdd[change] if change.is_a?(UpdateAddHtlc)
            end
            # TODO:
            return goto(self, data: store(data.copy(commitments: new_commitments)))
          when CommandAck

          when CommandClose
            local_script_pubkey = message[:script_pubkey]&.value || data[:commitments][:local_param][:default_final_script_pubkey]
            if data[:local_shutdown] && !data[:local_shutdown].is_a?(None)
              return handle_command_error(ClosingAlreadyInProgress.new(data[:commitments]), data)
            end

            if Commitment.local_has_unsigned_outgoing_htlcs?(data[:commitments])
              return handle_command_error(CannotCloseWithUnsignedOutgoingHtlcs.new(data[:commitments]), data)
            end

            unless Lightning::Transactions::Closing.valid_final_script_pubkey?(local_script_pubkey)
              return handle_command_error(InvalidFinalScript.new(data[:commitments]), data)
            end

            shutdown = Shutdown.new(channel_id: data.channel_id, scriptpubkey: local_script_pubkey)
            return goto(
              self,
              data: store(data.copy(local_shutdown: Some[Shutdown][shutdown])),
              sending: shutdown
            )
          when Shutdown
            unless Lightning::Transactions::Closing.valid_final_script_pubkey?(message.scriptpubkey)
              return handle_local_error(InvalidFinalScript.new(data[:commitments]), data)
            end
            if Commitment.remote_has_unsigned_outgoing_htlcs?(data[:commitments])
              return handle_local_error(CannotCloseWithUnsignedOutgoingHtlcs.new(data[:commitments]), data)
            end
            if Commitment.local_has_unsigned_outgoing_htlcs?(data[:commitments])
              match data[:commitments].remote_next_commit_info,
                    (on ~WaitingForRevocation do |wait|
                      new_commitments = data[:commitments].tap do |commitments|
                        commitments.remote_next_commit_info = wait.tap { |w| w.re_sign_asap = true }
                      end
                      return goto(self, data: data.copy(commitments: new_commitments, remote_shutdown: message))
                    end), (on ~String do |info|
                      channel << CommandSignature
                      return goto(self, data: data.copy(remote_shutdown: msg))
                    end)
            else
              local_shutdown, send_list =
                match data[:local_shutdown], (on Some[Shutdown].(~any) do |shutdown|
                  [shutdown, []]
                end), (on any do
                  script = data[:commitments][:local_param][:default_final_script_pubkey]
                  local_shutdown = Shutdown.new(channel_id: data.channel_id, scriptpubkey: script)
                  [local_shutdown, [local_shutdown]]
                end)
              if data[:commitments].has_no_pending_htlcs?
                negotiating = Negotiating.new(channel, context)
                closing = Lightning::Transactions::Closing.make_first_closing_tx(
                  data[:commitments],
                  Bitcoin::Script.parse_from_payload(local_shutdown[:scriptpubkey].htb),
                  Bitcoin::Script.parse_from_payload(message.scriptpubkey.htb)
                )
                return goto(
                  negotiating,
                  data: store(DataNegotiating[
                    data[:commitments],
                    local_shutdown,
                    message,
                    [ClosingTxProposed[closing.tx, closing.closing_signed]],
                    Algebrick::None
                  ]),
                  sending: send_list + [closing.closing_signed]
                )
              else
                return goto(
                  Shutdowning.new(channel, context),
                  data: store(DataShutdown[
                    data[:commitments],
                    local_shutdown,
                    message
                  ]),
                  sending: send_list
                )
              end
            end
          when WatchEventConfirmed
            return [self, data] unless message[:event_type] == 'deeply_confirmed'
            return [self, data] unless data[:channel_announcement].is_a? None

            output_index = data[:commitments][:commit_input].out_point.index
            short_channel_id = Channel.to_short_id(message[:block_height], message[:tx_index], output_index)
            channel_update =
              if short_channel_id == data[:short_channel_id]
                data[:channel_update]
              else
                context.broadcast << ShortChannelIdAssigned.build(
                  channel,
                  channel_id: data.channel_id,
                  short_channel_id: short_channel_id
                )
                Lightning::Router::Announcements.make_channel_update(
                  context.node_params.chain_hash,
                  context.node_params.private_key,
                  context.remote_node_id,
                  short_channel_id,
                  data[:channel_update].cltv_expiry_delta,
                  data[:channel_update].htlc_minimum_msat,
                  data[:channel_update].fee_base_msat,
                  data[:channel_update].fee_proportional_millionths
                )
              end

            # TODO : check channel_flags
            local_announcement_signatures = Lightning::Router::Announcements.make_announcement_signatures(
              context.node_params,
              data[:commitments],
              short_channel_id
            )
            goto(
              self,
              data: data.copy(short_channel_id: short_channel_id, buried: 1, channel_update: channel_update),
              sending: local_announcement_signatures
            )
          when AnnouncementSignatures
            if data[:buried] == 1
              local_announcement_signatures = Lightning::Router::Announcements.make_announcement_signatures(
                context.node_params,
                data[:commitments],
                data[:short_channel_id]
              )

              if data[:channel_announcement].is_a? None
                channel_announcement = Lightning::Router::Announcements.make_channel_announcement(
                  context.node_params.chain_hash,
                  local_announcement_signatures[:short_channel_id],
                  data[:commitments][:local_param][:node_id],
                  data[:commitments][:remote_param][:node_id],
                  data[:commitments][:local_param][:funding_priv_key].pubkey,
                  data[:commitments][:remote_param][:funding_pubkey],
                  local_announcement_signatures[:node_signature],
                  message.node_signature,
                  local_announcement_signatures[:bitcoin_signature],
                  message.bitcoin_signature
                )
                goto(self, data: store(data.copy(channel_announcement: Some[ChannelAnnouncement][channel_announcement])))
              else
                # Resend AnnouncementSignatures
                goto(self, data: data, sending: local_announcement_signatures)
              end
            else
              task = Concurrent::TimerTask.new(execution_interval: 60) do
                channel.reference << message
                task.shutdown
              end
              task.execute
              [self, data]
            end
          end
        end

        def handle_command_error(cause, data)
          log(Logger::ERROR, '/channel_state/normal', "handle_command_error:cause=#{cause}")
          [self, data]
        end

        def handle_local_error(cause, data)
          log(Logger::ERROR, '/channel_state/normal', "handle_local_error:cause=#{cause}")
          [self, data]
        end

        def handle_command_success(channel, commitment, msg)
          [self, commitment]
          # replying "ok"
        end

        def origin(c)
          match c[:upstream_opt], (on Algebrick::Some.(~any) do |u|
            Lightning::Payment::Relayer::Relayed[u.channel_id, u.id, u.amount_msat, u.amount_msat]
          end), (on Algebrick::None do
            Lightning::Payment::Relayer::Local
          end)
        end
      end
    end
  end
end
