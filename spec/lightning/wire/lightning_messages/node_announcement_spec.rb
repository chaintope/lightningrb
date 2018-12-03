# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::NodeAnnouncement do
  let(:signature) do
    '3045022100d7d6b702edcc1c5bf58a60693b7863dacb40c25f0034064daa3057' \
    '6b672987e002200e7ba19352bbb239cbc136f37ecf231b38a90e7c3fc85485d1' \
    'f845d14da601b1'
  end
  let(:flen) { 0 }
  let(:features) { ''.htb }
  let(:timestamp) { 1 }
  let(:node_id) { build(:key, :remote_funding_pubkey).pubkey }
  let(:node_rgb_color) { [100, 200, 44] }
  let(:node_alias) { 'node-alias' }
  let(:addrlen) { 1 }
  let(:addresses) { ['192.168.1.42:42000'] }
  let(:payload) do
    '0101d7d6b702edcc1c5bf58a60693b7863dacb40c25f0034064daa30576b6729' \
    '87e00e7ba19352bbb239cbc136f37ecf231b38a90e7c3fc85485d1f845d14da6' \
    '01b1000000000001030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a1' \
    '32cec6d3c39fa711c164c82c6e6f64652d616c69617300000000000000000000' \
    '000000000000000000000000000701c0a8012aa410'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:signature]).to eq signature }
    it { expect(subject[:flen]).to eq flen }
    it { expect(subject[:features]).to eq features }
    it { expect(subject[:timestamp]).to eq timestamp }
    it { expect(subject[:node_id]).to eq node_id }
    it { expect(subject[:node_rgb_color]).to eq node_rgb_color }
    it { expect(subject[:node_alias]).to eq node_alias }
    it { expect(subject[:addrlen]).to eq addrlen }
    it { expect(subject[:addresses]).to eq addresses }
  end

  describe '#to_payload' do
    subject do
      described_class[
        signature,
        flen,
        features,
        timestamp,
        node_id,
        node_rgb_color,
        node_alias,
        addrlen,
        addresses
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end

  describe '#valid?' do
    subject { announcement.valid? }

    let(:announcement) do
      described_class[
        signature,
        flen,
        features,
        timestamp,
        node_id,
        node_rgb_color,
        node_alias,
        addrlen,
        addresses
      ]
    end

    it { is_expected.to be_truthy }

    xdescribe 'MUST place non-zero typed address descriptors in ascending order.' do
      let(:addrlen) { 2 }
      let(:addresses) { ['192.168.1.42:3000', '0000:0000:0000:0000:0000:ffff:c0a8:012a:2000'] }

      it { is_expected.to be_falsy }
    end

    xdescribe 'MUST NOT create a `type 1` OR `type 2` address descriptor with `port` equal
    to 0.' do
      describe 'type 1' do
        let(:addrlen) { 1 }
        let(:addresses) { ['192.168.1.42:0'] }

        it { is_expected.to be_falsy }
      end

      describe 'type 2' do
        let(:addrlen) { 1 }
        let(:addresses) { ['0000:0000:0000:0000:0000:ffff:c0a8:012a:0'] }

        it { is_expected.to be_falsy }
      end
    end

    xdescribe 'MUST NOT include more than one `address descriptor` of the same type.' do
      let(:addrlen) { 1 }
      let(:addresses) { ['192.168.1.42:4000', '192.168.1.42:3000'] }

      it { is_expected.to be_falsy }
    end

    describe 'SHOULD set `flen` to the minimum length required to hold the `features`
    bits it sets.' do
      let(:flen) { 1 }
      let(:features) { '0101'.htb }

      it { is_expected.to be_falsy }
    end
  end
end
