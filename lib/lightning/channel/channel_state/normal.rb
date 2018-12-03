# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Normal < ChannelState
        def next(message, data)
          match message, (on ~CommandAddHtlc do |c|
            return handle_command_error("error", data) if data.shutting_down?
            match Commitment.send_add(data[:commitments], c, origin(c), context.wallet.spv),
                  (on Array.(~Commitments, ~UpdateAddHtlc) do |commitments1, msg|
                    channel << CommandSignature if c[:commit]
                    return goto(self, data: data.copy(commitments: commitments1), sending: msg)
                  end), (on ~any do |error|
                    handle_command_error(error, data)
                  end)
          end), (on ~UpdateAddHtlc do |msg|
            match Commitment.receive_add(data[:commitments], msg, context.wallet.spv),
                  (on ~Commitments do |commitments1|
                    return goto(self, data: data.copy(commitments: commitments1))
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~CommandFulfillHtlc do |c|
            match Commitment.send_fulfill(data[:commitments], c),
                  (on Array.(~Commitments, ~UpdateFulfillHtlc) do |commitments1, msg|
                    channel << CommandSignature if c[:commit]
                    return goto(self, data: data.copy(commitments: commitments1), sending: msg)
                  end), (on ~any do |error|
                    handle_command_error(error, data)
                  end)
          end), (on ~UpdateFulfillHtlc do |msg|
            match Commitment.receive_fulfill(data[:commitments], msg),
                  (on Array.(~Commitments, ~any, ~any) do |commitments1, origin, htlc|
                    context.relayer << Lightning::Payment::Relayer::ForwardFulfill[msg, origin, htlc]
                    return goto(self, data: data.copy(commitments: commitments1))
                  end), (on Array do
                    [self, data]
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~CommandFailHtlc do |c|
            match Commitment.send_fail(data[:commitments], c, context.node_params.private_key),
                  (on Array.(~Commitments, ~UpdateFailHtlc) do |commitments1, msg|
                    channel << CommandSignature if c[:commit]
                    return goto(self, data: data.copy(commitments: commitments1), sending: msg)
                  end), (on ~any do |error|
                    handle_command_error(error, data)
                  end)
          end), (on ~UpdateFailHtlc do |msg|
            match Commitment.receive_fail(data[:commitments], msg),
                  (on Array.(~Commitments, ~any, ~any) do |commitments1, origin, htlc|
                    context.relayer << Lightning::Payment::Relayer::ForwardFail[msg, origin, htlc]
                    return goto(self, data: data.copy(commitments: commitments1))
                  end), (on Array do
                    [self, data]
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~CommandFailMalformedHtlc do |c|
            match Commitment.send_fail_malformed(data[:commitments], c),
                  (on Array.(~Commitments, ~UpdateFailMalformedHtlc) do |commitments1, msg|
                    channel << CommandSignature if c[:commit]
                    return goto(self, data: data.copy(commitments: commitments1), sending: msg)
                  end), (on ~any do |error|
                    handle_command_error(error, data)
                  end)
          end), (on ~UpdateFailMalformedHtlc do |msg|
            match Commitment.receive_fail_malformed(data[:commitments], msg),
                  (on Array.(~Commitments, ~any, ~any) do |commitments1, origin, htlc|
                    context.relayer << Lightning::Payment::Relayer::ForwardFailMalformed[msg, origin, htlc]
                    return goto(self, data: data.copy(commitments: commitments1))
                  end), (on Array do
                    [self, data]
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~CommandUpdateFee do |c|
            match Commitment.send_fee(data[:commitments], c),
                  (on Array.(~Commitments, ~UpdateFee) do |commitments1, msg|
                    channel << CommandSignature if c[:commit]
                    return goto(self, data: data.copy(commitments: commitments1), sending: msg)
                  end), (on ~any do |error|
                    handle_command_error(error, data)
                  end)
          end), (on ~UpdateFee do |msg|
            match Commitment.receive_fee(data[:commitments], msg),
                  (on Array.(~Commitments, ~any, ~any) do |commitments1, origin, htlc|
                    return goto(self, data: data.copy(commitments: commitments1))
                  end), (on Array do
                    [self, data]
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~CommandSignature do |c|
            match data[:commitments][:remote_next_commit_info],
                  (on ~WaitingForRevocation do |wait|
                    wait1 = WaitingForRevocation[
                      wait[:next_remote_commit],
                      wait[:sent],
                      wait[:sent_after_local_commit_index],
                      true
                    ]
                    commitments1 = data[:commitments].copy(remote_next_commit_info: wait1)
                    return goto(self, data: data.copy(commitments: commitments1))
                  end), (on ~any do |info|
                    unless Commitment.local_has_changes?(data[:commitments])
                      return [self, data]
                    end
                    match Commitment.send_commit(data[:commitments]),
                          (on Array.(~Commitments, ~CommitmentSigned) do |commitments1, msg|
                            commitments1[:local_changes][:signed].each do |change|
                              match change, (on ~UpdateFulfillHtlc do |update|
                                context.relayer << CommandAck[update.channel_id, update.id]
                              end), (on any do
                              end)
                            end
                            return goto(self, data: store(data.copy(commitments: commitments1)), sending: msg)
                          end), (on ~any do |error|
                            handle_command_error(error, data)
                          end)
                  end)
          end), (on ~CommitmentSigned do |msg|
            match Commitment.receive_commit(data[:commitments], msg),
                  (on Array.(~Commitments, ~any) do |commitments1, revocation|
                    if Commitment.local_has_changes?(commitments1)
                      channel << CommandSignature
                    end
                    context.broadcast << ChannelSignatureReceived[channel, commitments1]
                    return goto(self, data: store(data.copy(commitments: commitments1)), sending: revocation)
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~RevokeAndAck do |msg|
            match Commitment.receive_revocation(data[:commitments], msg),
                  (on ~Commitments do |commitments1|
                    data[:commitments][:remote_changes][:signed].each do |change|
                      context.relayer << ForwardAdd[change] if change.is_a?(UpdateAddHtlc)
                    end
                    # TODO:
                    return goto(self, data: store(data.copy(commitments: commitments1)))
                  end), (on ~any do |error|
                    handle_local_error(error, data)
                  end)
          end), (on ~CommandClose do |c|
            local_script_pubkey =
              c[:script_pubkey]&.value || data[:commitments][:local_param][:default_final_script_pubkey]
            if data[:local_shutdown] && !data[:local_shutdown].is_a?(None)
              return handle_command_error(ClosingAlreadyInProgress.new(data[:commitments]), data)
            end
            if Commitment.local_has_unsigned_outgoing_htlcs?(data[:commitments])
              return handle_command_error(CannotCloseWithUnsignedOutgoingHtlcs.new(data[:commitments]), data)
            end
            unless Lightning::Transactions::Closing.valid_final_script_pubkey?(local_script_pubkey)
              return handle_command_error(InvalidFinalScript.new(data[:commitments]), data)
            end
            shutdown = Shutdown[data.channel_id, local_script_pubkey.htb.bytesize, local_script_pubkey]
            return goto(
              self,
              data: store(data.copy(local_shutdown: Some[Shutdown][shutdown])),
              sending: shutdown
            )
          end), (on ~Shutdown do |msg|
            unless Lightning::Transactions::Closing.valid_final_script_pubkey?(msg[:scriptpubkey])
              return handle_local_error(InvalidFinalScript.new(data[:commitments]), data)
            end
            if Commitment.remote_has_unsigned_outgoing_htlcs?(data[:commitments])
              return handle_local_error(CannotCloseWithUnsignedOutgoingHtlcs.new(data[:commitments]), data)
            end
            if Commitment.local_has_unsigned_outgoing_htlcs?(data[:commitments])
              match data[:commitments].remote_next_commit_info,
                    (on ~WaitingForRevocation do |wait|
                      commitments1 = data[:commitments].tap do |commitments|
                        commitments.remote_next_commit_info = wait.tap { |w| w.re_sign_asap = true }
                      end
                      return goto(self, data: data.copy(commitments: commitments1, remote_shutdown: msg))
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
                  local_shutdown = Shutdown[data.channel_id, script.htb.bytesize, script]
                  [local_shutdown, [local_shutdown]]
                end)
              if data[:commitments].has_no_pending_htlcs?
                negotiating = Negotiating.new(channel, context)
                closing = Lightning::Transactions::Closing.make_first_closing_tx(
                  data[:commitments],
                  Bitcoin::Script.parse_from_payload(local_shutdown[:scriptpubkey].htb),
                  Bitcoin::Script.parse_from_payload(msg[:scriptpubkey].htb)
                )
                return goto(
                  negotiating,
                  data: store(DataNegotiating[
                    data[:commitments],
                    local_shutdown,
                    msg,
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
                    msg
                  ]),
                  sending: send_list
                )
              end
            end
          end), (on ~WatchEventConfirmed do |msg|
            return [self, data] unless msg[:event_type] == 'deeply_confirmed'
            return [self, data] unless data[:channel_announcement].is_a? None
            output_index = data[:commitments][:commit_input].out_point.index
            short_channel_id = Channel.to_short_id(msg[:block_height], msg[:tx_index], output_index)
            channel_update =
              if short_channel_id == data[:short_channel_id]
                data[:channel_update]
              else
                context.broadcast << ShortChannelIdAssigned[channel, data.channel_id, short_channel_id]
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
          end), (on ~AnnouncementSignatures do |msg|
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
                  msg[:node_signature],
                  local_announcement_signatures[:bitcoin_signature],
                  msg[:bitcoin_signature]
                )
                goto(self, data: store(data.copy(channel_announcement: Some[ChannelAnnouncement][channel_announcement])))
              else
                # Resend AnnouncementSignatures
                goto(self, data: data, sending: local_announcement_signatures)
              end
            else
              task = Concurrent::TimerTask.new(execution_interval: 60) do
                channel.reference << msg
                task.shutdown
              end
              task.execute
              [self, data]
            end
          end)
        end

        def handle_command_error(cause, data)
          log(Logger::DEBUG, '/channel_state/normal', "handle_command_error:cause=#{cause}")
          [self, data]
        end

        def handle_local_error(cause, data)
          log(Logger::DEBUG, '/channel_state/normal', "handle_local_error:cause=#{cause}")
          [self, data]
        end

        def handle_command_success(channel, commitment, msg)
          [self, commitment]
          # replying "ok"
        end

        def origin(c)
          match c[:upstream_opt], (on Algebrick::Some.(~UpdateAddHtlc) do |u|
            Lightning::Payment::Relayer::Relayed[u.channel_id, u.id, u.amount_msat, u.amount_msat]
          end), (on Algebrick::None do
            Lightning::Payment::Relayer::Local
          end)
        end
      end
    end
  end
end
