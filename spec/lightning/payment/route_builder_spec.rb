# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Payment::RouteBuilder do
  include Lightning::Payment::RouteBuilder

  let(:keys) do
    [
      Bitcoin::Key.new(priv_key: '41' * 32),
      Bitcoin::Key.new(priv_key: '42' * 32),
      Bitcoin::Key.new(priv_key: '43' * 32),
      Bitcoin::Key.new(priv_key: '44' * 32),
      Bitcoin::Key.new(priv_key: '45' * 32),
    ]
  end
  let(:public_keys) { keys.map(&:pubkey) }
  let(:sig) { keys[0].sign(Bitcoin.sha256('')).bth + '01' }
  let(:channel_update) do
    Lightning::Wire::LightningMessages::ChannelUpdate.new(
      signature: Lightning::Wire::Signature.new(value: sig),
      chain_hash1: '00' * 32,
      short_channel_id: 0,
      timestamp: 0,
      message_flags: "00",
      channel_flags: "00",
      cltv_expiry_delta: 42000,
      htlc_minimum_msat: 0,
      fee_base_msat: 0,
      fee_proportional_millionths: 0,
      htlc_maximum_msat: 0
    )
  end
  let(:channel_update_ab) do
    channel_update.copy(short_channel_id: 1, cltv_expiry_delta: 4, fee_base_msat: 642000, fee_proportional_millionths: 7)
  end
  let(:channel_update_bc) do
    channel_update.copy(short_channel_id: 2, cltv_expiry_delta: 5, fee_base_msat: 153000, fee_proportional_millionths: 4)
  end
  let(:channel_update_cd) do
    channel_update.copy(short_channel_id: 3, cltv_expiry_delta: 10, fee_base_msat: 60000, fee_proportional_millionths: 1)
  end
  let(:channel_update_de) do
    channel_update.copy(short_channel_id: 4, cltv_expiry_delta: 7, fee_base_msat: 766000, fee_proportional_millionths: 10)
  end

  # simple route a -> b -> c -> d -> e
  let(:hops) do
    [
      Lightning::Router::Messages::Hop[public_keys[0], public_keys[1], channel_update_ab],
      Lightning::Router::Messages::Hop[public_keys[1], public_keys[2], channel_update_bc],
      Lightning::Router::Messages::Hop[public_keys[2], public_keys[3], channel_update_cd],
      Lightning::Router::Messages::Hop[public_keys[3], public_keys[4], channel_update_de],
    ]
  end
  let(:final_amount_msat) { 42_000_000 }
  let(:current_block_count) { 420_000 }
  let(:final_expiry) { 420_009 }
  let(:payment_hash) { "\x42" * 32 }
  let(:expiry_de) { final_expiry }
  let(:amount_de) { final_amount_msat }
  let(:fee_d) { node_fee(channel_update_de.fee_base_msat, channel_update_de.fee_proportional_millionths, amount_de) }
  let(:expiry_cd) { expiry_de + channel_update_de.cltv_expiry_delta }
  let(:amount_cd) { amount_de + fee_d }
  let(:fee_c) { node_fee(channel_update_cd.fee_base_msat, channel_update_cd.fee_proportional_millionths, amount_cd) }
  let(:expiry_bc) { expiry_cd + channel_update_cd.cltv_expiry_delta }
  let(:amount_bc) { amount_cd + fee_c }
  let(:fee_b) { node_fee(channel_update_bc.fee_base_msat, channel_update_bc.fee_proportional_millionths, amount_bc) }
  let(:expiry_ab) { expiry_bc + channel_update_bc.cltv_expiry_delta }
  let(:amount_ab) { amount_bc + fee_b }

  describe '.node_fee' do
    subject { node_fee(base_msat, proportional, msat) }

    let(:base_msat) { 200 }
    let(:proportional) { 2000 }
    let(:msat) { 4999999 }

    # fee_base_msat + ( amount_msat * fee_proportional_millionths / 1000000 )
    it { is_expected.to eq 10199 }
  end

  describe '.build_payloads' do
    subject { build_payloads(final_amount_msat, final_expiry, hops[1..-1]) }

    let(:expected) do
      [
        Lightning::Onion::PerHop.new(channel_update_bc.short_channel_id, amount_bc, expiry_bc, "\x00" * 12),
        Lightning::Onion::PerHop.new(channel_update_cd.short_channel_id, amount_cd, expiry_cd, "\x00" * 12),
        Lightning::Onion::PerHop.new(channel_update_de.short_channel_id, amount_de, expiry_de, "\x00" * 12),
        Lightning::Onion::PerHop.new(0, final_amount_msat, final_expiry, "\x00" * 12),
      ]
    end

    it { expect(subject[:msat]).to eq amount_ab }
    it { expect(subject[:expiry]).to eq expiry_ab }
    it { expect(subject[:payloads].map(&:to_payload)).to eq expected.map(&:to_payload) }
  end

  describe '.build_onion' do
    let(:nodes) { hops.map(&:next_node_id) }
    let(:payloads) { build_payloads(final_amount_msat, final_expiry, hops[1..-1])[:payloads] }

    it do
      packet_b, _ = build_onion(nodes, payloads, payment_hash)
      expect(packet_b.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH

      hop_data_b, packet_c = Lightning::Onion::Sphinx.parse(keys[1].priv_key, packet_b.to_payload)
      expect(packet_c.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_b.per_hop.amt_to_forward).to eq amount_bc
      expect(hop_data_b.per_hop.outgoing_cltv_value).to eq expiry_bc

      hop_data_c, packet_d = Lightning::Onion::Sphinx.parse(keys[2].priv_key, packet_c.to_payload)
      expect(packet_d.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_c.per_hop.amt_to_forward).to eq amount_cd
      expect(hop_data_c.per_hop.outgoing_cltv_value).to eq expiry_cd

      hop_data_d, packet_e = Lightning::Onion::Sphinx.parse(keys[3].priv_key, packet_d.to_payload)
      expect(packet_e.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_d.per_hop.amt_to_forward).to eq amount_de
      expect(hop_data_d.per_hop.outgoing_cltv_value).to eq expiry_de

      hop_data_e, packet_final = Lightning::Onion::Sphinx.parse(keys[4].priv_key, packet_e.to_payload)
      expect(packet_final.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_e.per_hop.amt_to_forward).to eq final_amount_msat
      expect(hop_data_e.per_hop.outgoing_cltv_value).to eq final_expiry
    end
  end

  describe '.build_command' do
    let(:cltv_expiry) do
      final_expiry +
      channel_update_bc.cltv_expiry_delta +
      channel_update_cd.cltv_expiry_delta +
      channel_update_de.cltv_expiry_delta
    end

    it 'build a command with no hops' do
      command, _ = build_command(final_amount_msat, final_expiry, payment_hash, [hops[0]])
      hop_data, _ = Lightning::Onion::Sphinx.parse(keys[1].priv_key, command[:onion].htb)
      expect(command[:amount_msat]).to eq final_amount_msat
      expect(command[:cltv_expiry]).to eq final_expiry
      expect(command[:payment_hash]).to eq payment_hash
      expect(command[:onion].htb.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data.per_hop.amt_to_forward).to eq final_amount_msat
      expect(hop_data.per_hop.outgoing_cltv_value).to eq final_expiry
    end

    it 'build a command including the onion' do
      command, _ = build_command(final_amount_msat, final_expiry, payment_hash, hops)
      expect(command[:amount_msat]).to be > final_amount_msat
      expect(command[:cltv_expiry]).to eq cltv_expiry
      expect(command[:payment_hash]).to eq payment_hash
      expect(command[:onion].htb.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH

      hop_data_b, packet_c = Lightning::Onion::Sphinx.parse(keys[1].priv_key, command[:onion].htb)
      expect(packet_c.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_b.per_hop.amt_to_forward).to eq amount_bc
      expect(hop_data_b.per_hop.outgoing_cltv_value).to eq expiry_bc

      hop_data_c, packet_d = Lightning::Onion::Sphinx.parse(keys[2].priv_key, packet_c.to_payload)
      expect(packet_d.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_c.per_hop.amt_to_forward).to eq amount_cd
      expect(hop_data_c.per_hop.outgoing_cltv_value).to eq expiry_cd

      hop_data_d, packet_e = Lightning::Onion::Sphinx.parse(keys[3].priv_key, packet_d.to_payload)
      expect(packet_e.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_d.per_hop.amt_to_forward).to eq amount_de
      expect(hop_data_d.per_hop.outgoing_cltv_value).to eq expiry_de

      hop_data_e, packet_final = Lightning::Onion::Sphinx.parse(keys[4].priv_key, packet_e.to_payload)
      expect(packet_final.to_payload.bytesize).to eq Lightning::Onion::Sphinx::PACKET_LENGTH
      expect(hop_data_e.per_hop.amt_to_forward).to eq final_amount_msat
      expect(hop_data_e.per_hop.outgoing_cltv_value).to eq final_expiry
    end
  end
end
