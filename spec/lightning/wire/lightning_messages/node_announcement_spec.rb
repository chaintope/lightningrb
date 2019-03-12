# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::NodeAnnouncement do
  let(:signature) do
    Lightning::Wire::Signature.new(value:
      '3045022100d7d6b702edcc1c5bf58a60693b7863dacb40c25f0034064daa3057' \
      '6b672987e002200e7ba19352bbb239cbc136f37ecf231b38a90e7c3fc85485d1' \
      'f845d14da601b1'
    )
  end
  let(:flen) { 0 }
  let(:features) { ''.htb }
  let(:timestamp) { 1 }
  let(:node_id) { build(:key, :remote_funding_pubkey).pubkey }
  let(:node_rgb_color) { (100 << 16) + (200 << 8) + 44 }
  let(:node_alias) { "node-alias\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" }
  let(:addrlen) { 7 }
  let(:addresses) { '01c0a8012aa410' }
  let(:payload) do
    '0101d7d6b702edcc1c5bf58a60693b7863dacb40c25f0034064daa30576b6729' \
    '87e00e7ba19352bbb239cbc136f37ecf231b38a90e7c3fc85485d1f845d14da6' \
    '01b1000000000001030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a1' \
    '32cec6d3c39fa711c164c82c6e6f64652d616c69617300000000000000000000' \
    '000000000000000000000000000701c0a8012aa410'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    let(:parsed_address) { Lightning::Wire::LightningMessages::Generated::IP4.new(ipv4_addr: '192.168.1.42', port: '42000') }
    it { expect(subject.signature).to eq signature }
    it { expect(subject.features).to eq features }
    it { expect(subject.timestamp).to eq timestamp }
    it { expect(subject.node_id).to eq node_id }
    it { expect(subject.node_rgb_color).to eq node_rgb_color }
    it { expect(subject.node_alias).to eq node_alias }
    it { expect(subject.addresses).to eq addresses }
    it { expect(subject.parsed_addresses).to eq [parsed_address] }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        signature: signature,
        features: features,
        timestamp: timestamp,
        node_id: node_id,
        node_rgb_color: node_rgb_color,
        node_alias: node_alias,
        addresses: addresses
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end

  describe '#valid?' do
    subject { announcement.valid? }

    let(:announcement) do
      described_class.new(
        signature: signature,
        features: features,
        timestamp: timestamp,
        node_id: node_id,
        node_rgb_color: node_rgb_color,
        node_alias: node_alias,
        addresses: addresses
      )
    end

    it { is_expected.to be_truthy }

    xdescribe 'MUST place non-zero typed address descriptors in ascending order.' do
      let(:addresses) { ['01c0a8012aa410', '0200000000000000000000ffffc0a8012a1000'] }

      it { is_expected.to be_falsy }
    end

    xdescribe 'MUST NOT create a `type 1` OR `type 2` address descriptor with `port` equal
    to 0.' do
      describe 'type 1' do
        let(:addresses) { ['01c0a8012a0000'] }

        it { is_expected.to be_falsy }
      end

      describe 'type 2' do
        let(:addresses) { ['0200000000000000000000ffffc0a8012a0000'] }

        it { is_expected.to be_falsy }
      end
    end

    xdescribe 'MUST NOT include more than one `address descriptor` of the same type.' do
      let(:addrlen) { 1 }
      let(:addresses) { ['01c0a8012aa410', '01c0a8012aa411'] }

      it { is_expected.to be_falsy }
    end

    xdescribe 'SHOULD set `flen` to the minimum length required to hold the `features`
    bits it sets.' do
      let(:features) { '0101'.htb }

      it { is_expected.to be_falsy }
    end
  end
end
