# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Crypto::DER do
  let(:der) do
    '30440220774a03d7dfda37030654b8f9bc93c00c68a5902560582b2bd7daa9a3' \
    '6aaaccb302204ca905e987633c6ecdc499f16224d660d039b1ca58796febf903' \
    '0b1b61fb95c1'.htb
  end

  describe '.encode' do
    subject { described_class.encode(r, s) }

    let(:r) { '774a03d7dfda37030654b8f9bc93c00c68a5902560582b2bd7daa9a36aaaccb3'.htb }
    let(:s) { '4ca905e987633c6ecdc499f16224d660d039b1ca58796febf9030b1b61fb95c1'.htb }

    it { is_expected.to eq der }
  end

  describe '.decode' do
    subject { described_class.decode(der) }

    let(:sig) do
      '774a03d7dfda37030654b8f9bc93c00c68a5902560582b2bd7daa9a36aaaccb3' \
      '4ca905e987633c6ecdc499f16224d660d039b1ca58796febf9030b1b61fb95c1'
    end

    it { is_expected.to eq sig }
  end
end
