# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::Funding do
  describe '.make_funding_utxo' do
    # local_funding_pubkey: 023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb
    # remote_funding_pubkey: 030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c1
    # funding witness script = 5221023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb
    #     21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c152ae
    subject do
      described_class.make_funding_utxo(
        funding_tx_hash,
        funding_tx_output_index,
        funding_satoshis,
        local_funding_pubkey,
        remote_funding_pubkey
      )
    end

    let(:funding_tx_hash) { 'fd2105607605d2302994ffea703b09f66b6351816ee737a93e42a841ea20bbad' }
    let(:funding_tx_output_index) { 0 }
    let(:funding_satoshis) { 10_000_000 }
    let(:local_funding_pubkey) { '023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb' }
    let(:remote_funding_pubkey) { '030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c1' }
    let(:expected) { '0020c015c4a6be010e21657068fc2e6a9d02b27ebe4d490a25846f7237f104d1a3cd' }

    it { expect(subject.script_pubkey.to_hex).to eq expected }
  end
end
