# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::RouteFinder do
  describe '#find' do
    subject { described_class.find(source, target, updates, assisted_routes) }

    let(:public_key0) { '02eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619' }
    let(:public_key1) { '0324653eac434488002cc06bbfb7f10fe18991e35f9fe4302dbea6d2353dc0ab1c' }
    let(:public_key2) { '027f31ebc5462c1fdce1b737ecff52d37d75dea43ce11c74d25aa297165faa2007' }
    let(:public_key3) { '032c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991' }
    let(:public_key4) { '02edabbd16b41c8371b92ef2f04c1185b4f03b6dcd52ba9b78d9d7c89c8f221145' }
    let(:source) { public_key0 }
    let(:target) { public_key4 }
    let(:updates) do
      {
        Lightning::Router::Messages::ChannelDesc[1, public_key1, public_key2] => build(:channel_update),
        Lightning::Router::Messages::ChannelDesc[0, public_key0, public_key1] => build(:channel_update),
        Lightning::Router::Messages::ChannelDesc[3, public_key4, public_key3] => build(:channel_update),
        Lightning::Router::Messages::ChannelDesc[2, public_key2, public_key3] => build(:channel_update),
      }
    end
    let(:assisted_routes) { [] }

    describe '1st node' do
      it { expect(subject[0][:node_id]).to eq source }
    end

    describe 'next to 1st node' do
      it { expect(subject[0][:next_node_id]).to eq public_key1 }
    end

    describe '2nd node' do
      it { expect(subject[1][:node_id]).to eq public_key1 }
    end

    describe 'next to 2nd node' do
      it { expect(subject[1][:next_node_id]).to eq public_key2 }
    end

    describe '3rd node' do
      it { expect(subject[2][:node_id]).to eq public_key2 }
    end

    describe 'next to 3rd node' do
      it { expect(subject[2][:next_node_id]).to eq public_key3 }
    end

    describe '4th node' do
      it { expect(subject[3][:node_id]).to eq public_key3 }
    end

    describe 'next to 4th node' do
      it { expect(subject[3][:next_node_id]).to eq public_key4 }
    end
  end
end