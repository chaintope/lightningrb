# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::LightningMessage do
  let(:der) do
    '3044022006738efd3950b5afde00bb3a751446b6f66a9f3aa922270f77e393d0' \
    'f94ef2ea022011e92f342b707aefd3defee91bdbb1a2fc2b824c9a542903d878' \
    '9b2a7e1a6088'
  end

  let(:sig) do
    '06738efd3950b5afde00bb3a751446b6f66a9f3aa922270f77e393d0f94ef2ea' \
    '11e92f342b707aefd3defee91bdbb1a2fc2b824c9a542903d8789b2a7e1a6088'
  end

  describe '.wire2der' do
    subject { Lightning::Wire::LightningMessages.wire2der(sig.htb) }

    it { is_expected.to eq der }
  end

  describe '.der2wire' do
    subject { Lightning::Wire::LightningMessages.der2wire(der.htb).bth }

    it { is_expected.to eq sig }
  end
end
