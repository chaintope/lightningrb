# frozen_string_literal: true

require 'spec_helper'
require 'jsonclient'

describe Lightning::Utils::BlockGenerator do
  describe '#on_message' do
    let(:setting) { {:domain=>"http://localhost:18555", :username=>"username", :password=>"password", :endpoint=>"http://localhost:18555"} }
    let(:generator) { described_class.spawn(:generator, setting) }

    before { JSONClient.any_instance.stub(:post).and_return({}) }

    context ':generate' do
      subject do
        generator << :generate
        generator.ask(:await).wait
      end

      it do
        expect_any_instance_of(JSONClient).to receive(:post)
        subject
      end

      context 'after terminate!' do
        it do
          generator << :terminate!
          generator.ask(:await).wait
          expect_any_instance_of(JSONClient).not_to receive(:post)
          subject
        end
      end
    end
  end
end
