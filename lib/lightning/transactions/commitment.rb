# frozen_string_literal: true

module Lightning
  module Transactions
    module Commitment
      extend Algebrick::Matching
      extend Concurrent::Concern::Logging
      include Lightning::Crypto
      include Lightning::Transactions
      include Lightning::Utils
      include Lightning::Channel::Messages
      include Lightning::Wire::LightningMessages
      include Lightning::Exceptions

      def self.encode_tx_number(commitment_tx_number)
        [0x80000000 | (commitment_tx_number >> 24), (commitment_tx_number & 0xffffff) | 0x20000000]
      end

      def self.decode_tx_number(sequence, locktime)
        ((sequence & 0xffffff) << 24) + (locktime & 0xffffff)
      end

      def self.obscured_commit_tx_number(
        commitment_tx_number,
        is_funder,
        local_payment_base_point,
        remote_payment_base_point
      )
        # BOLT 3:
        # SHA256(payment-basepoint from open_channel || payment-basepoint from accept_channel)
        h =
          if is_funder
            Bitcoin.sha256(local_payment_base_point.htb + remote_payment_base_point.htb)
          else
            Bitcoin.sha256(remote_payment_base_point.htb + local_payment_base_point.htb)
          end
        blind = h[-6..-1] || h
        commitment_tx_number ^ blind.bth.to_i(16)
      end

      def self.make_first_commitment_txs(
        temporary_channel_id,
        local_param,
        remote_param,
        funding_satoshis,
        push_msat,
        initial_feerate_per_kw,
        funding_tx_txid,
        funding_tx_output_index,
        remote_first_per_commitment_point
      )
        to_local_msat = local_param.funder? ? funding_satoshis * 1000 - push_msat : push_msat
        to_remote_msat = local_param.funder? ? push_msat : funding_satoshis * 1000 - push_msat

        local_spec = CommitmentSpec[Set.new, initial_feerate_per_kw, to_local_msat, to_remote_msat]
        remote_spec = CommitmentSpec[Set.new, initial_feerate_per_kw, to_remote_msat, to_local_msat]

        commitment_input_utxo = Funding.make_funding_utxo(
          funding_tx_txid,
          funding_tx_output_index,
          funding_satoshis,
          local_param.funding_priv_key.pubkey,
          remote_param.funding_pubkey
        )

        local_per_commitment_point = Key.per_commitment_point(local_param.sha_seed, 0)
        local_commitment_tx, = make_local_txs(
          0,
          local_param,
          remote_param,
          commitment_input_utxo,
          local_per_commitment_point,
          local_spec
        )
        remote_commitment_tx, = make_remote_txs(
          0,
          local_param,
          remote_param,
          commitment_input_utxo,
          remote_first_per_commitment_point,
          remote_spec
        )
        [local_spec, local_commitment_tx, remote_spec, remote_commitment_tx]
      end

      def self.make_commitment_tx(
        commitment_input_utxo,
        commit_tx_number,
        local_payment_basepoint,
        remote_payment_basepoint,
        local_is_funder,
        local_dust_limit_satoshis,
        local_revocation_pubkey,
        to_local_delay,
        local_delayed_payment_pubkey,
        remote_payment_pubkey,
        local_htlc_pubkey,
        remote_htlc_pubkey,
        spec
      )
        fee = Fee.commit_tx_fee(local_dust_limit_satoshis, spec)
        to_local_amount, to_remote_amount =
          if local_is_funder
            [spec.to_local_msat / 1000 - fee, spec.to_remote_msat / 1000]
          else
            [spec.to_local_msat / 1000, spec.to_remote_msat / 1000 - fee]
          end
        to_local_script = Scripts.to_local(
          local_revocation_pubkey,
          local_delayed_payment_pubkey,
          to_self_delay: to_local_delay
        )
        log(Logger::DEBUG, 'commitments', "make_commitment_tx spec=#{spec}")
        log(Logger::DEBUG, 'commitments', "make_commitment_tx fee=#{fee}")
        log(Logger::DEBUG, 'commitments', "make_commitment_tx local_dust_limit_satoshis=#{local_dust_limit_satoshis}")
        log(Logger::DEBUG, 'commitments', "make_commitment_tx revocation_pubkey=#{local_revocation_pubkey}")
        log(Logger::DEBUG, 'commitments', "make_commitment_tx delayed_payment_pubkey=#{local_delayed_payment_pubkey}")
        log(Logger::DEBUG, 'commitments', "make_commitment_tx to_self_delay=#{to_local_delay}")
        log(Logger::DEBUG, 'commitments', "make_commitment_tx to_local_script=#{to_local_script}")

        to_local_output =
          if to_local_amount >= local_dust_limit_satoshis
            script = Bitcoin::Script.to_p2wsh(to_local_script)
            Bitcoin::TxOut.new(value: to_local_amount, script_pubkey: script)
          end
        to_remote_output =
          if to_remote_amount >= local_dust_limit_satoshis
            script = Scripts.to_remote(remote_payment_pubkey)
            Bitcoin::TxOut.new(value: to_remote_amount, script_pubkey: script)
          end
        to_htlc_offered_outputs =
          Fee.trim_offered_htlcs(local_dust_limit_satoshis, spec).map do |htlc|
            script = Bitcoin::Script.to_p2wsh(
              Scripts.offered_htlc(
                local_revocation_pubkey,
                local_htlc_pubkey,
                remote_htlc_pubkey,
                htlc.add.payment_hash
              )
            )
            Bitcoin::TxOut.new(value: htlc.add.amount_msat / 1000, script_pubkey: script)
          end
        to_htlc_received_outputs =
          Fee.trim_received_htlcs(local_dust_limit_satoshis, spec).map do |htlc|
            script = Bitcoin::Script.to_p2wsh(
              Scripts.received_htlc(
                local_revocation_pubkey,
                local_htlc_pubkey,
                remote_htlc_pubkey,
                htlc.add.payment_hash,
                htlc.add.cltv_expiry
              )
            )
            Bitcoin::TxOut.new(value: htlc.add.amount_msat / 1000, script_pubkey: script)
          end

        tx_number = obscured_commit_tx_number(
          commit_tx_number,
          local_is_funder,
          local_payment_basepoint,
          remote_payment_basepoint
        )

        sequence, lock_time = encode_tx_number(tx_number)

        tx = Bitcoin::Tx.new
        tx.version = 2
        tx.lock_time = lock_time
        tx.inputs << Bitcoin::TxIn.new(
          out_point: commitment_input_utxo.out_point, sequence: sequence
        )
        tx.outputs << to_local_output if to_local_output
        tx.outputs << to_remote_output if to_remote_output
        (to_htlc_offered_outputs + to_htlc_received_outputs).each do |output|
          tx.outputs << output
        end
        TransactionWithUtxo[LexicographicalOrdering.sort(tx), commitment_input_utxo]
      end

      def self.find_script_pubkey_index(tx, script_pubkey)
        output_index = tx.outputs.index { |output| output.script_pubkey == script_pubkey }
        if output_index.nil? || output_index.negative?
          raise OutputNotFound.new(tx, script_pubkey)
        end
        output_index
      end

      def self.make_local_txs(
        commit_tx_number,
        local_param,
        remote_param,
        commitment_input_utxo,
        local_per_commitment_point,
        spec
      )
        _local_payment_pubkey = Key.derive_public_key(
          local_param.payment_basepoint, local_per_commitment_point
        )
        local_delayed_payment_pubkey = Key.derive_public_key(
          local_param.delayed_payment_basepoint, local_per_commitment_point
        )
        local_htlc_pubkey = Key.derive_public_key(
          local_param.htlc_basepoint, local_per_commitment_point
        )
        remote_payment_pubkey = Key.derive_public_key(
          remote_param.payment_basepoint, local_per_commitment_point
        )
        remote_htlc_pubkey = Key.derive_public_key(
          remote_param.htlc_basepoint, local_per_commitment_point
        )
        local_revocation_pubkey = Key.revocation_public_key(
          remote_param.revocation_basepoint, local_per_commitment_point
        )
        commit_tx = make_commitment_tx(
          commitment_input_utxo,
          commit_tx_number,
          local_param.payment_basepoint,
          remote_param.payment_basepoint,
          local_param.funder?,
          local_param.dust_limit_satoshis,
          local_revocation_pubkey,
          remote_param.to_self_delay,
          local_delayed_payment_pubkey,
          remote_payment_pubkey,
          local_htlc_pubkey,
          remote_htlc_pubkey,
          spec
        )
        log(
          Logger::DEBUG,
          'commitments',
          "build local commitment tx: num=#{commit_tx_number} txid=#{commit_tx.tx.txid} tx=#{commit_tx.tx.to_payload.bth}"
        )
        htlc_timeout_txs, htlc_success_txs = make_htlc_txs(
          commit_tx,
          local_param.dust_limit_satoshis,
          local_revocation_pubkey,
          remote_param.to_self_delay,
          local_delayed_payment_pubkey,
          local_htlc_pubkey,
          remote_htlc_pubkey,
          spec
        )
        [commit_tx, htlc_timeout_txs, htlc_success_txs]
      end

      def self.make_remote_txs(
        commit_tx_number,
        local_param,
        remote_param,
        commitment_input_utxo,
        remote_per_commitment_point,
        spec
      )
        local_payment_pubkey = Key.derive_public_key(
          local_param.payment_basepoint, remote_per_commitment_point
        )
        local_htlc_pubkey = Key.derive_public_key(
          local_param.htlc_basepoint, remote_per_commitment_point
        )
        _remote_payment_pubkey = Key.derive_public_key(
          remote_param.payment_basepoint, remote_per_commitment_point
        )
        remote_delayed_payment_pubkey = Key.derive_public_key(
          remote_param.delayed_payment_basepoint, remote_per_commitment_point
        )
        remote_htlc_pubkey = Key.derive_public_key(
          remote_param.htlc_basepoint, remote_per_commitment_point
        )
        remote_revocation_pubkey = Key.revocation_public_key(
          local_param.revocation_basepoint, remote_per_commitment_point
        )
        commit_tx = make_commitment_tx(
          commitment_input_utxo,
          commit_tx_number,
          remote_param.payment_basepoint,
          local_param.payment_basepoint,
          !local_param.funder?,
          remote_param.dust_limit_satoshis,
          remote_revocation_pubkey,
          local_param.to_self_delay,
          remote_delayed_payment_pubkey,
          local_payment_pubkey,
          remote_htlc_pubkey,
          local_htlc_pubkey,
          spec
        )
        log(
          Logger::DEBUG,
          'commitments',
          "build remote commitment tx: num=#{commit_tx_number} txid=#{commit_tx.tx.txid} tx=#{commit_tx.tx.to_payload.bth}"
        )

        htlc_timeout_txs, htlc_success_txs = make_htlc_txs(
          commit_tx,
          remote_param.dust_limit_satoshis,
          remote_revocation_pubkey,
          local_param.to_self_delay,
          remote_delayed_payment_pubkey,
          remote_htlc_pubkey,
          local_htlc_pubkey,
          spec
        )
        [commit_tx, htlc_timeout_txs, htlc_success_txs]
      end

      def self.make_htlc_txs(
        commit_tx,
        local_dust_limit,
        local_revocation_pubkey,
        to_local_delay,
        local_delayed_payment_pubkey,
        local_htlc_pubkey,
        remote_htlc_pubkey,
        spec
      )
        htlc_timeout_txs = Fee.trim_offered_htlcs(local_dust_limit, spec).map do |htlc|
          HtlcTimeout.make_htlc_timeout_tx(
            commit_tx.tx,
            local_dust_limit,
            local_revocation_pubkey,
            to_local_delay,
            local_delayed_payment_pubkey,
            local_htlc_pubkey,
            remote_htlc_pubkey,
            spec.feerate_per_kw,
            htlc.add
          )
        end
        htlc_success_txs = Fee.trim_received_htlcs(local_dust_limit, spec).map do |htlc|
          HtlcSuccess.make_htlc_success_tx(
            commit_tx.tx,
            local_dust_limit,
            local_revocation_pubkey,
            to_local_delay,
            local_delayed_payment_pubkey,
            local_htlc_pubkey,
            remote_htlc_pubkey,
            spec.feerate_per_kw,
            htlc.add
          )
        end
        [htlc_timeout_txs, htlc_success_txs]
      end

      def self.send_add(commitments, cmd, origin, spv)
        log(Logger::DEBUG, 'commitments', "send_add")
        return InvalidPaymentHash.new(commitments, cmd) if cmd[:payment_hash].size != 64

        block_count = spv.blockchain_info['headers']
        if cmd[:cltv_expiry] <= block_count
          return ExpiryCannotBeInThePast.new(commitments, cmd, block_count)
        end
        return ExpiryTooLarge.new(commitments, cmd) if cmd[:cltv_expiry] >= 500_000_000

        if cmd[:amount_msat] < commitments[:remote_param][:htlc_minimum_msat]
          return HtlcValueTooSmall.new(commitments, cmd)
        end

        # for Bitcoin blockchain only
        return HtlcValueTooLarge.new(commitments, cmd) if cmd[:amount_msat] > 0x00000000FFFFFFFF

        add = UpdateAddHtlc.new(
          channel_id: commitments[:channel_id],
          id: commitments[:local_next_htlc_id],
          amount_msat: cmd[:amount_msat],
          payment_hash: cmd[:payment_hash],
          cltv_expiry: cmd[:cltv_expiry],
          onion_routing_packet: cmd[:onion]
        )
        commitments1 = add_local_proposal(
          commitments,
          add,
          local_next_htlc_id: commitments[:local_next_htlc_id] + 1,
          origin_channels: commitments[:origin_channels].merge(add.id => origin)
        )
        next_commitment_info = commitments1[:remote_next_commit_info]
        remote_commit1 =
          if next_commitment_info.is_a?(Lightning::Channel::Messages::WaitingForRevocation)
            next_commitment_info[:next_remote_commit]
          else
            commitments1[:remote_commit]
          end

        reduced = CommitmentSpec.reduce(
          remote_commit1[:spec],
          commitments1[:remote_changes][:acked],
          commitments1[:local_changes][:proposed]
        )

        htlc_value_in_flight = reduced.htlcs.sum { |htlc| htlc.add.amount_msat }
        if htlc_value_in_flight > commitments1[:remote_param][:max_htlc_value_in_flight_msat]
          return HtlcValueTooHighInFlight.new(commitments1, add)
        end

        accepted_htlcs = reduced.received.size
        if accepted_htlcs > commitments1[:remote_param][:max_accepted_htlcs]
          return TooManyAcceptedHtlcs.new(commitments1, add)
        end

        fees =
          if commitments1[:local_param][:funder] == 1
            Fee.commit_tx_fee(commitments1[:remote_param][:dust_limit_satoshis], reduced)
          else
            0
          end

        channel_reserve_satoshis = commitments1[:remote_param][:channel_reserve_satoshis]
        if missing?(reduced, channel_reserve_satoshis, fees)
          return InsufficientFunds.new(commitments1, add, reduced, fees)
        end

        [commitments1, add]
      end

      def self.receive_add(commitments, add, spv)
        log(Logger::DEBUG, 'commitments', "receive_add")
        raise UnexpectedHtlcId unless commitments[:remote_next_htlc_id] == add.id
        raise InvalidPaymentHash.new(commitments, add) unless add.payment_hash&.size == 64

        block_count = spv.blockchain_info['headers']
        raise ExpiryTooSmall.new(commitments, add) if add.cltv_expiry < block_count + 3
        raise ExpiryTooLarge.new(commitments, add) if add.cltv_expiry >= 500_000_000
        if add.amount_msat < commitments[:local_param][:htlc_minimum_msat]
          raise HtlcValueTooSmall.new(commitments, add)
        end

        # for Bitcoin blockchain only
        raise HtlcValueTooLarge.new(commitments, add) if add.amount_msat > 0x00000000FFFFFFFF

        commitments1 = add_remote_proposal(commitments, add, remote_next_htlc_id: commitments[:remote_next_htlc_id] + 1)
        reduced = CommitmentSpec.reduce(
          commitments1[:local_commit][:spec],
          commitments1[:local_changes][:acked],
          commitments1[:remote_changes][:proposed]
        )

        htlc_value_in_flight = reduced.htlcs.sum { |htlc| htlc.add.amount_msat }
        if htlc_value_in_flight > commitments1[:local_param][:max_htlc_value_in_flight_msat]
          raise HtlcValueTooHighInFlight.new(commitments1, add)
        end
        accepted_htlcs = reduced.received.size
        if accepted_htlcs > commitments1[:local_param][:max_accepted_htlcs]
          raise TooManyAcceptedHtlcs.new(commitments1, add)
        end
        fees =
          if commitments1[:local_param][:funder] == 1
            0
          else
            Fee.commit_tx_fee(commitments1[:local_param][:dust_limit_satoshis], reduced)
          end

        channel_reserve_satoshis = commitments1[:local_param][:channel_reserve_satoshis]
        if missing?(reduced, channel_reserve_satoshis, fees)
          raise InsufficientFunds.new(commitments1, add, reduced, fees)
        end
        commitments1
      end

      def self.send_fulfill(commitments, command)
        log(Logger::DEBUG, 'commitments', "send_fulfill")
        htlc = get_htlc_cross_signed(commitments, CommitmentSpec::RECEIVE, command.id)
        raise UnknownHtlcId.new(commitments, command.id) unless htlc
        exist =
          commitments[:local_changes][:proposed].any? do |proposed|
            case proposed
            when UpdateFulfillHtlc, UpdateFailHtlc, UpdateFailMalformedHtlc
              htlc.id == proposed.id
            else
              false
            end
          end
        raise UnknownHtlcId.new(commitments, command.id) if exist
        payment_hash = Bitcoin.sha256(command.r.htb).bth
        raise InvalidHtlcPreimage.new(htlc, payment_hash) unless htlc.payment_hash == payment_hash
        fulfill = UpdateFulfillHtlc.new(
          channel_id: commitments[:channel_id],
          id: command.id,
          payment_preimage: command.r
        )
        commitments1 = add_local_proposal(commitments, fulfill)
        [commitments1, fulfill]
      end

      def self.receive_fulfill(commitments, fulfill)
        log(Logger::DEBUG, 'commitments', "receive_fulfill")
        htlc = get_htlc_cross_signed(commitments, CommitmentSpec::OFFER, fulfill.id)
        raise UnknownHtlcId.new(commitments, fulfill.id) unless htlc
        payment_hash = Bitcoin.sha256(fulfill.payment_preimage.htb).bth
        raise InvalidHtlcPreimage.new(htlc, payment_hash) unless htlc.payment_hash == payment_hash
        [
          add_remote_proposal(commitments, fulfill),
          commitments[:origin_channels][fulfill.id],
          htlc,
        ]
      end

      def self.send_fail(commitments, command, node_secret)
        htlc = get_htlc_cross_signed(commitments, CommitmentSpec::RECEIVE, command.id)
        raise UnknownHtlcId.new(commitments, command.id) unless htlc
        exist =
          commitments[:local_changes][:proposed].any? do |proposed|
            case proposed
            when UpdateFulfillHtlc, UpdateFailHtlc, UpdateFailMalformedHtlc
              htlc.id == proposed.id
            else
              false
            end
          end
        raise UnknownHtlcId.new(commitments, command.id) if exist
        packet = Lightning::Onion::Sphinx.parse(node_secret, htlc.onion_routing_packet.htb)
        shared_secret = packet && packet[2]
        raise CannotExtractSharedSecret.new(packet) unless shared_secret
        reason = match command.reason, (on ~Lightning::Onion::FailureMessages::FailureMessage do |failure|
          Lightning::Onion::Sphinx.make_error_packet(shared_secret, failure)
        end), (on ~any do |forwarded|
          Lightning::Onion::Sphinx.forward_error_packet(forwarded, shared_secret)
        end)
        fail = UpdateFailHtlc.new(
          channel_id: commitments[:channel_id],
          id: command.id,
          reason: reason
        )
        commitments1 = add_local_proposal(commitments, fail)
        [commitments1, fail]
      end

      def self.receive_fail(commitments, fail)
        htlc = get_htlc_cross_signed(commitments, CommitmentSpec::OFFER, fail.id)
        raise UnknownHtlcId.new(commitments, fail.id) unless htlc

        [add_remote_proposal(commitments, fail), commitments[:origin_channels][fail.id], htlc]
      end

      def self.send_fail_malformed(commitments, command)
        raise InvalidFailureCode.new(command.failure_code) if command.failure_code & Lightning::Onion::FailureMessages::BADONION == 0

        htlc = get_htlc_cross_signed(commitments, CommitmentSpec::RECEIVE, command.id)
        raise UnknownHtlcId.new(commitments, command.id) unless htlc
        exist =
          commitments[:local_changes][:proposed].any? do |h|
            case proposed
            when UpdateFulfillHtlc, UpdateFailHtlc, UpdateFailMalformedHtlc
              htlc.id == proposed.id
            else
              false
            end
          end

        raise UnknownHtlcId.new(commitments, command.id) if exist
        fail = UpdateFailMalformedHtlc.new(
          channel_id: commitments[:channel_id],
          id: command.id,
          sha256_of_onion: command.onion_hash,
          failure_code: command.failure_code
        )
        commitments1 = add_local_proposal(commitments, fail)
        [commitments1, fail]
      end

      def self.receive_fail_malformed(commitments, fail)
        raise InvalidFailureCode.new(fail.failure_code) if fail.failure_code & Lightning::Onion::FailureMessages::BADONION == 0

        htlc = get_htlc_cross_signed(commitments, CommitmentSpec::OFFER, fail.id)
        raise UnknownHtlcId.new(commitments, fail.id) unless htlc

        [add_remote_proposal(commitments, fail), commitments[:origin_channels][fail.id], htlc]
      end

      def self.send_fee(commitments, command)
        raise FundeeCannotSendUpdateFee.new('fundee cannot send update fee') if commitments[:local_param][:funder] == 0

        fee = UpdateFee.new(channel_id: commitments[:channel_id], feerate_per_kw: command[:feerate_per_kw])
        commitments1 = add_local_proposal(commitments, fee)
        reduced = CommitmentSpec.reduce(
          commitments1[:remote_commit][:spec],
          commitments1[:remote_changes][:acked],
          commitments1[:local_changes][:proposed]
        )

        fees = Fee.commit_tx_fee(commitments1[:remote_param][:dust_limit_satoshis], reduced)
        channel_reserve_satoshis = commitments1[:remote_param][:channel_reserve_satoshis]
        raise CannotAffordFees.new(reduced, channel_reserve_satoshis, fees) if missing?(reduced, channel_reserve_satoshis, fees)
        [commitments1, fee]
      end

      def self.receive_fee(commitments, fee, node_params)
        raise FundeeCannotSendUpdateFee.new('fundee cannot send update fee') if commitments[:local_param][:funder] == 1

        if fee.feerate_per_kw < node_params.minimum_feerate_per_kw
          raise FeerateTooSmall.new("feerate_per_kw is too small: #{fee.feerate_per_kw} < #{node_params.minimum_feerate_per_kw}")
        end

        if fee.feerate_per_kw > node_params.maximum_feerate_per_kw
          raise FeerateTooLarge.new("feerate_per_kw is unreasonably large: #{fee.feerate_per_kw} > #{node_params.maximum_feerate_per_kw}")
        end

        commitments1 = add_remote_proposal(commitments, fee)
        reduced = CommitmentSpec.reduce(
          commitments1[:local_commit][:spec],
          commitments1[:local_changes][:acked],
          commitments1[:remote_changes][:proposed]
        )

        fees = Fee.commit_tx_fee(commitments1[:remote_param][:dust_limit_satoshis], reduced)
        channel_reserve_satoshis = commitments1[:local_param][:channel_reserve_satoshis]
        if missing?(reduced, channel_reserve_satoshis, fees)
          raise CannotAffordFees.new(reduced, channel_reserve_satoshis, fees)
        end
        commitments1
      end

      def self.send_commit(commitments)
        log(Logger::DEBUG, 'commitments', "send_commit")
        remote_next_per_commitment_point = commitments[:remote_next_commit_info]
        raise CannotSignBeforeRevocation.new(commitments) if remote_next_per_commitment_point.is_a? WaitingForRevocation
        raise CannotSignWithoutChanges.new(commitments) unless local_has_changes?(commitments)

        spec = CommitmentSpec.reduce(
          commitments[:remote_commit].spec, commitments[:remote_changes].acked, commitments[:local_changes].proposed
        )
        remote_commit_tx, htlc_timeout_txs, htlc_success_txs =
          make_remote_txs(
            commitments[:remote_commit].index + 1,
            commitments[:local_param],
            commitments[:remote_param],
            commitments[:commit_input],
            remote_next_per_commitment_point,
            spec
          )
        log(Logger::DEBUG, 'commitments', "commitments:#{commitments.inspect}")
        log(Logger::DEBUG, 'commitments', "remote_next_per_commitment_point:#{remote_next_per_commitment_point}")
        log(Logger::DEBUG, 'commitments', "remote_commit_tx:#{remote_commit_tx.tx.to_payload.bth}")
        log(Logger::DEBUG, 'commitments', "htlc_timeout_txs:#{htlc_timeout_txs.first&.to_payload&.bth}")
        log(Logger::DEBUG, 'commitments', "htlc_success_txs:#{htlc_success_txs.first&.to_payload&.bth}")

        sig =
          begin
            Transactions.sign(remote_commit_tx.tx, remote_commit_tx.utxo, commitments[:local_param].funding_priv_key)
          rescue StandardError => _
            raise InvalidCommitmentSignature.new(commitments[:channel_id], remote_commit_tx.tx)
          end

        sorted_htlc_txs = (htlc_timeout_txs + htlc_success_txs).sort do |tx|
          tx.inputs[0].out_point.index
        end
        key = Key.derive_private_key(commitments[:local_param].htlc_key.to_s(16).rjust(64, '0'), remote_next_per_commitment_point)
        htlc_sigs = sorted_htlc_txs.map do |tx|
          index = 0
          amount = tx.utxo.value
          redeem_script = tx.utxo.redeem_script
          sighash = tx.tx.sighash_for_input(index, redeem_script, amount: amount, sig_version: :witness_v0)
          Lightning::Wire::Signature.new(value: Bitcoin::Key.new(priv_key: key).sign(sighash).bth)
        end
        commit_sig = CommitmentSigned.new(
          channel_id: commitments[:channel_id],
          signature: Lightning::Wire::Signature.new(value: sig),
          htlc_signature: htlc_sigs
        )

        remote_next_commit_info = WaitingForRevocation[
          RemoteCommit[
            commitments[:remote_commit].index + 1,
            spec,
            remote_commit_tx.tx.txid,
            remote_next_per_commitment_point
          ],
          commit_sig,
          commitments[:local_commit][:index]
        ]
        commitments1 = commitments.copy(
          local_changes: commitments[:local_changes].copy(proposed: [], signed: commitments[:local_changes][:proposed]),
          remote_changes: commitments[:remote_changes].copy(acked: [], signed: commitments[:remote_changes][:acked]),
          remote_next_commit_info: remote_next_commit_info
        )
        [commitments1, commit_sig]
      end

      def self.receive_commit(commitments, commit)
        log(Logger::DEBUG, 'commitments', "receive_commit")
        raise CannotSignWithoutChanges.new(commitments) unless remote_has_changes?(commitments)
        spec = CommitmentSpec.reduce(
          commitments[:local_commit][:spec],
          commitments[:local_changes][:acked],
          commitments[:remote_changes][:proposed]
        )
        local_per_commitment_point = Key.per_commitment_point(
          commitments[:local_param].sha_seed, commitments[:local_commit][:index] + 1
        )
        local_commit_tx, htlc_timeout_txs, htlc_success_txs = make_local_txs(
          commitments[:local_commit][:index] + 1,
          commitments[:local_param],
          commitments[:remote_param],
          commitments[:commit_input],
          local_per_commitment_point,
          spec
        )
        signed_commit_tx =
          begin
            sig = Transactions.sign(local_commit_tx.tx, local_commit_tx.utxo, commitments[:local_param].funding_priv_key)
            Transactions.add_sigs(
              local_commit_tx.tx,
              local_commit_tx.utxo,
              commitments[:local_param].funding_priv_key.pubkey,
              commitments[:remote_param].funding_pubkey,
              sig,
              commit[:signature].value
            )
          rescue => e

            puts e
            raise InvalidCommitmentSignature.new(commitments[:channel_id], local_commit_tx.tx)
          end

        unless Transactions.spendable?(signed_commit_tx)
          raise InvalidCommitmentSignature.new(commitments[:channel_id], signed_commit_tx)
        end

        sorted_htlc_txs = (htlc_timeout_txs + htlc_success_txs).sort_by do |tx|
          tx.tx.inputs[0].out_point.index
        end
        raise HtlcSigCountMismatch.new(commit.htlc_signature.size, sorted_htlc_txs.size) if commit.htlc_signature.size != sorted_htlc_txs.size
        htlc_sigs = sorted_htlc_txs.map do |tx|
          key = Key.derive_private_key(commitments[:local_param].htlc_key.to_s(16).rjust(64, '0'), local_per_commitment_point)
          index = 0
          amount = tx.utxo.value
          redeem_script = tx.utxo.redeem_script
          sighash = tx.tx.sighash_for_input(index, redeem_script, amount: amount, sig_version: :witness_v0)
          Bitcoin::Key.new(priv_key: key).sign(sighash).bth
        end
        remote_htlc_pubkey = Key.derive_public_key(
          commitments[:remote_param].htlc_basepoint, local_per_commitment_point
        )
        htlc_txs_and_sigs = [sorted_htlc_txs, htlc_sigs, commit[:htlc_signature]].transpose
        htlc_txs_and_sigs = htlc_txs_and_sigs.select do |htlc_tx, local_sig, remote_sig|
          match htlc_tx, (on ~HtlcTimeout do |htlc_timeout|
            htlc_timeout.add_sigs(local_sig, remote_sig.value)
            unless Transactions.spendable?(htlc_timeout.tx)
              raise InvalidHtlcSignature.new(local_sig, remote_sig.value)
            end
            unless Transactions.check_sig(htlc_tx, remote_sig, remote_htlc_pubkey)
              raise InvalidHtlcSignature.new(local_sig, remote_sig.value)
            end
            [htlc_timeout, local_sig, remote_sig.value]
          end), (on ~HtlcSuccess do |htlc_success|
            unless Transactions.check_sig(htlc_tx, remote_sig, remote_htlc_pubkey)
              raise InvalidHtlcSignature.new(local_sig, remote_sig.value)
            end
            [htlc_tx, local_sig, remote_sig.value]
          end)
        end

        local_per_commitment_secret = Key.per_commitment_secret(
          commitments[:local_param].sha_seed, commitments[:local_commit].index
        )
        local_next_per_commitment_point = Key.per_commitment_point(
          commitments[:local_param].sha_seed, commitments[:local_commit].index + 2
        )
        revocation = RevokeAndAck.new(
          channel_id: commitments[:channel_id],
          per_commitment_secret: local_per_commitment_secret,
          next_per_commitment_point: local_next_per_commitment_point
        )

        local_commit1 = LocalCommit[
          commitments[:local_commit].index + 1,
          spec,
          PublishableTxs[TransactionWithUtxo[signed_commit_tx, commitments[:commit_input]], htlc_txs_and_sigs]
        ]
        our_changes1 = commitments[:local_changes].copy(acked: [])
        their_changes1 = commitments[:remote_changes].copy(
          proposed: [], acked: commitments[:remote_changes].acked + commitments[:remote_changes].proposed
        )
        completed_outgoing_htlcs = commitments[:local_commit][:spec][:htlcs].select do |htlc|
          htlc.direction == CommitmentSpec::OFFER
        end.map do |htlc|
          htlc.add.id
        end - local_commit1[:spec][:htlcs].select do |htlc|
          htlc.direction == CommitmentSpec::OFFER
        end.map do |htlc|
          htlc.add.id
        end
        origin_channels1 = commitments[:origin_channels].delete_if { |k, v| completed_outgoing_htlcs.include?(k) }
        commitments = commitments.copy(
          local_commit: local_commit1,
          local_changes: our_changes1,
          remote_changes: their_changes1,
          origin_channels: origin_channels1
        )
        [commitments, revocation]
      end

      def self.receive_revocation(commitments, revocation)
        log(Logger::DEBUG, 'commitments', "receive_revocation")
        remote_next_commit_info = commitments[:remote_next_commit_info]
        unless remote_next_commit_info
          raise UnexpectedRevocation.new(commitments)
        end
        per_commitment_point = Bitcoin::Key.new(priv_key: revocation[:per_commitment_secret]).pubkey
        if per_commitment_point != commitments[:remote_commit][:remote_per_commitment_point]
          raise InvalidRevocation.new(revocation)
        end
        match remote_next_commit_info, (on WaitingForRevocation.(~any, any, any, any) do |next_commit|
          local_changes = commitments[:local_changes].copy(
            signed: [], acked: commitments[:local_changes].acked + commitments[:local_changes].signed
          )
          remote_changes = commitments[:remote_changes].copy(signed: [])
          remote_per_commitment_secrets =
            add_hash(
              commitments[:remote_per_commitment_secrets],
              revocation[:per_commitment_secret],
              0xFFFFFFFFFFFF - commitments[:remote_commit][:index]
            )
          commitments.copy(
            local_changes: local_changes,
            remote_changes: remote_changes,
            remote_commit: next_commit,
            remote_next_commit_info: revocation[:next_per_commitment_point],
            remote_per_commitment_secrets: remote_per_commitment_secrets
          )
        end)
      end

      def self.local_has_unsigned_outgoing_htlcs?(commitments)
        commitments[:local_changes].proposed.any? { |u| u.is_a? Lightning::Wire::LightningMessages::UpdateAddHtlc }
      end

      def self.remote_has_unsigned_outgoing_htlcs?(commitments)
        commitments[:remote_changes].proposed.any? { |u| u.is_a? Lightning::Wire::LightningMessages::UpdateAddHtlc }
      end

      def self.add_local_proposal(
        commitments,
        proposal,
        local_next_htlc_id: commitments[:local_next_htlc_id],
        origin_channels: commitments[:origin_channels]
      )
        local_changes = commitments[:local_changes].copy(proposed: commitments[:local_changes][:proposed] + [proposal])
        commitments.copy(
          local_changes: local_changes,
          local_next_htlc_id: local_next_htlc_id,
          origin_channels: origin_channels
        )
      end

      def self.add_remote_proposal(commitments, proposal, remote_next_htlc_id: commitments[:remote_next_htlc_id])
        remote_changes = commitments[:remote_changes].copy(proposed: commitments[:remote_changes][:proposed] + [proposal])
        commitments.copy(remote_changes: remote_changes, remote_next_htlc_id: remote_next_htlc_id)
      end

      def self.get_htlc_cross_signed(commitments, direction, htlc_id)
        remote_signed = commitments[:local_commit][:spec][:htlcs].find do |htlc|
          htlc.direction == direction && htlc.add.id == htlc_id
        end
        if commitments[:remote_next_commit_info].is_a? WaitingForRevocation
          commit = commitments[:remote_next_commit_info][:next_remote_commit]
        end
        local_signed = (commit || commitments[:remote_commit]).spec.htlcs.find do |htlc|
          htlc.direction != direction && htlc.add.id == htlc_id
        end
        return unless remote_signed
        return unless local_signed
        local_signed.add
      end

      def self.missing?(reduced, channel_reserve_satoshis, fees)
        missing = reduced[:to_remote_msat] / 1000 - channel_reserve_satoshis - fees
        missing.negative?
      end

      def self.local_has_changes?(commitments)
        !(commitments[:remote_changes][:acked].empty? && commitments[:local_changes][:proposed].empty?)
      end

      def self.remote_has_changes?(commitments)
        !(commitments[:local_changes][:acked].empty? && commitments[:remote_changes][:proposed].empty?)
      end

      def self.add_hash(chain, hash, index)
        ShaChain.insert_secret(
          hash,
          index,
          chain
        )
      end
    end
  end
end
