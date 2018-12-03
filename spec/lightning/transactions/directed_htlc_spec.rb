# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::DirectedHtlc do
  describe 'encode/decode' do
    subject { Lightning::Transactions::DirectedHtlc.load(directed_htlc.to_payload) }

    let(:directed_htlc) { build(:directed_htlc).get }

    it { expect(subject[0].to_payload.bth).to eq directed_htlc.to_payload.bth }
  end
end
