# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Crypto::TransportHandler do
  # 08-transport.md#appendix-a-transport-test-vectors
  describe 'Transport Test Vectors' do
    let(:session) { spawn_dummy_actor(name: :session) }
    let(:transport) { spawn_dummy_actor(name: :transport) }

    let(:complete) do
      Lightning::Wire::HandshakeMessages::HandshakeCompleted[session, transport, static_key, remote_key]
    end

    describe 'Initiator Tests' do
      let(:static_key) { '1111111111111111111111111111111111111111111111111111111111111111' }
      let(:remote_key) { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
      let(:ephemeral_key) { '1212121212121212121212121212121212121212121212121212121212121212' }
      let(:writer) do
        keypairs = { s: static_key.htb, e: ephemeral_key.htb, rs: remote_key.htb }
        initiator = Noise::Connection::Initiator.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs)
        initiator.prologue = Lightning::Crypto::TransportHandler::PROLOGUE
        initiator
      end
      let(:state) { Lightning::Crypto::TransportHandler::TransportHandlerStateHandshake.new(transport, session, static_key, writer) }
      let(:input2) { '0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae' }
      let(:received2) { Lightning::Wire::HandshakeMessages::Received[input2.htb] }
      let(:act3) do
        Lightning::Wire::HandshakeMessages::Act[
          '00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
          '55361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e1' \
          '39ba'.htb,
          session
        ]
      end

      before { writer.start_handshake }

      describe 'transport-initiator successful handshake' do
        it do
          expect(transport.parent).to receive(:<<).with(act3).ordered
          expect(transport.parent).to receive(:<<).with(complete).ordered

          writer.write_message('')
          state.next(received2)
          expect(writer.handshake_finished).to be_truthy
        end
      end

      describe 'transport-initiator act2 short read test' do
        let(:input2) { '0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730' }

        it do
          expect(transport.parent).not_to receive(:<<)
          writer.write_message('')
          state.next(received2)
          expect(writer.handshake_finished).to be_falsy
        end
      end

      describe 'transport-initiator act2 bad version test' do
        let(:input2) { '0102466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae' }

        it do
          writer.write_message('')
          expect { state.next(received2) }.to raise_error(Lightning::Exceptions::InvalidTransportVersion)
        end
      end

      describe 'transport-initiator act2 bad key serialization test' do
        let(:input2) { '0004466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae' }

        it do
          writer.write_message('')
          expect { state.next(received2) }.to raise_error(Noise::Exceptions::InvalidPublicKeyError)
        end
      end

      describe 'transport-initiator act2 bad MAC test' do
        let(:input2) { '0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730af' }

        it do
          writer.write_message('')
          expect { state.next(received2) }.to raise_error(Noise::Exceptions::DecryptError)
        end
      end
    end
    describe 'Responder Tests' do
      let(:static_key) { '2121212121212121212121212121212121212121212121212121212121212121' }
      let(:remote_key) { '034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa' }
      let(:ephemeral_key) { '2222222222222222222222222222222222222222222222222222222222222222' }
      let(:reader) do
        keypairs = { s: static_key.htb, e: ephemeral_key.htb }
        responder = Noise::Connection::Responder.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs)
        responder.prologue = Lightning::Crypto::TransportHandler::PROLOGUE
        responder
      end
      let(:state) { Lightning::Crypto::TransportHandler::TransportHandlerStateHandshake.new(transport, session, static_key, reader) }
      let(:input1) { '00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a' }
      let(:received1) { Lightning::Wire::HandshakeMessages::Received[input1.htb] }
      let(:act2) do
        Lightning::Wire::HandshakeMessages::Act[
          '0002466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f276e2470b93aac583c9ef6eafca3f730ae'.htb,
          session
        ]
      end
      let(:input3) do
        '00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
        '55361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e1' \
        '39ba'
      end
      let(:received3) { Lightning::Wire::HandshakeMessages::Received[input3.htb] }
      let(:transport) { spawn_dummy_actor(name: :transport) }

      before { reader.start_handshake }

      describe 'transport-responder successful handshake' do
        it do
          expect(transport.parent).to receive(:<<).with(act2).ordered
          expect(transport.parent).to receive(:<<).with(complete).ordered

          state.next(received1)
          state.next(received3)
          expect(reader.handshake_finished).to be_truthy
        end
      end

      describe 'transport-responder act1 short read test' do
        let(:input1) { '00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c' }

        it do
          expect(transport.parent).not_to receive(:<<)
          state.next(received1)
          expect(reader.handshake_finished).to be_falsy
        end
      end

      describe 'transport-responder act1 bad version test' do
        let(:input1) { '01036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a' }

        it do
          expect(transport.parent).not_to receive(:<<)
          expect { state.next(received1) }.to raise_error(Lightning::Exceptions::InvalidTransportVersion)
        end
      end

      describe 'transport-responder act1 bad key serialization test' do
        let(:input1) { '00046360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6a' }

        it do
          expect(transport.parent).not_to receive(:<<)
          expect { state.next(received1) }.to raise_error(Noise::Exceptions::InvalidPublicKeyError)
        end
      end

      describe 'transport-responder act1 bad MAC test' do
        let(:input1) { '00036360e856310ce5d294e8be33fc807077dc56ac80d95d9cd4ddbd21325eff73f70df6086551151f58b8afe6c195782c6b' }

        it do
          expect(transport.parent).not_to receive(:<<)
          expect { state.next(received1) }.to raise_error(Noise::Exceptions::DecryptError)
        end
      end

      describe 'transport-responder act3 bad version test' do
        let(:input3) do
          '01b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
          '55361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e1' \
          '39ba'
        end

        it do
          expect(transport.parent).to receive(:<<).with(act2)
          state.next(received1)
          expect { state.next(received3) }.to raise_error(Lightning::Exceptions::InvalidTransportVersion)
        end
      end

      describe 'transport-responder act3 short read test' do
        let(:input3) do
          '00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
          '55361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e1' \
          '39'
        end

        it do
          expect(transport.parent).to receive(:<<).with(act2).ordered
          expect(transport.parent).not_to receive(:<<).with(complete).ordered

          state.next(received1)
          state.next(received3)
          expect(reader.handshake_finished).to be_falsy
        end
      end

      describe 'transport-responder act3 bad MAC for ciphertext test' do
        let(:input3) do
          '00c9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
          '55361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e1' \
          '39ba'
        end

        it do
          expect(transport.parent).to receive(:<<).with(act2).ordered
          expect(transport.parent).not_to receive(:<<).with(complete).ordered

          state.next(received1)
          expect { state.next(received3) }.to raise_error(Noise::Exceptions::DecryptError)
        end
      end

      describe 'transport-responder act3 bad rs test' do
        let(:input3) do
          '00bfe3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
          '5536ad09a8ee351870c2bb7f78b754a26c6cef79a98d25139c856d7efd252c2a' \
          'e73c'
        end

        it do
          expect(transport.parent).to receive(:<<).with(act2).ordered
          expect(transport.parent).not_to receive(:<<).with(complete).ordered

          state.next(received1)
          expect { state.next(received3) }.to raise_error(Noise::Exceptions::InvalidPublicKeyError)
        end
      end

      describe 'transport-responder act3 bad MAC test' do
        let(:input3) do
          '00b9e3a702e93e3a9948c2ed6e5fd7590a6e1c3a0344cfc9d5b57357049aa223' \
          '55361aa02e55a8fc28fef5bd6d71ad0c38228dc68b1c466263b47fdf31e560e1' \
          '39bb'
        end

        it do
          expect(transport.parent).to receive(:<<).with(act2).ordered
          expect(transport.parent).not_to receive(:<<).with(complete).ordered

          state.next(received1)
          expect { state.next(received3) }.to raise_error(Noise::Exceptions::DecryptError)
        end
      end
    end
  end

  # 08-transport.md#message-encryption-tests
  describe Lightning::Crypto::TransportHandler::TransportHandlerState do
    let(:static_key) { '1111111111111111111111111111111111111111111111111111111111111111' }
    let(:remote_key) { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    let(:ephemeral_key) { '1212121212121212121212121212121212121212121212121212121212121212' }

    let(:ck) { '919219dbb2920afa8db80f9a51787a840bcf111ed8d588caf9ab4be716e42b01'.htb }
    let(:sk) { '969ab31b4d288cedf6218839b27a3e2140827047f2c0f01bf5c04435d43511a9'.htb }
    let(:rk) { 'bb9020b8965f4df047e07f955f3c4b88418984aadc5cdb35096b9ea8fa5c3442'.htb }

    # for test
    class Noise::Connection::Base
      def handshake_finished!
        @handshake_finished = true
      end
    end

    # for test
    class Noise::State::SymmetricState
      def initialize_chaining_key(ck)
        @ck = ck
      end
    end

    let(:connection) do
      keypairs = { s: static_key.htb, e: ephemeral_key.htb, rs: remote_key.htb }
      Noise::Connection::Initiator.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs).tap do |c|
        c.prologue = Lightning::Crypto::TransportHandler::PROLOGUE
        c.start_handshake
        cipher_state_encrypt = Noise::State::CipherState.new(cipher: c.protocol.cipher_fn)
        cipher_state_encrypt.initialize_key(sk)
        cipher_state_decrypt = Noise::State::CipherState.new(cipher: c.protocol.cipher_fn)
        c.handshake_state.symmetric_state.initialize_chaining_key(ck)
        c.handshake_done(cipher_state_encrypt, cipher_state_decrypt)
        c.handshake_finished!
      end
    end

    let(:session) { spawn_dummy_actor(name: :session) }
    let(:transport) { spawn_dummy_actor(name: :transport) }
    let(:state) { Lightning::Crypto::TransportHandler::TransportHandlerState.new(transport, session, static_key, connection) }

    describe 'encrypt' do
      subject { state.encrypt('68656c6c6f'.htb).bth }

      it { is_expected.to eq 'cf2b30ddf0cf3f80e7c35a6e6730b59fe802473180f396d88a8fb0db8cbcf25d2f214cf9ea1d95' }
    end
    describe 'key rotation' do
      def loop(state, count, ciphertexts: [])
        if count == 0
          ciphertexts
        else
          ciphertext = state.encrypt('68656c6c6f'.htb)
          ciphertexts << ciphertext
          loop(state, count - 1, ciphertexts: ciphertexts)
        end
      end

      subject { loop(state, 1002) }

      let(:cipher0) { 'cf2b30ddf0cf3f80e7c35a6e6730b59fe802473180f396d88a8fb0db8cbcf25d2f214cf9ea1d95' }
      let(:cipher1) { '72887022101f0b6753e0c7de21657d35a4cb2a1f5cde2650528bbc8f837d0f0d7ad833b1a256a1' }
      let(:cipher500) { '178cb9d7387190fa34db9c2d50027d21793c9bc2d40b1e14dcf30ebeeeb220f48364f7a4c68bf8' }
      let(:cipher501) { '1b186c57d44eb6de4c057c49940d79bb838a145cb528d6e8fd26dbe50a60ca2c104b56b60e45bd' }
      let(:cipher1000) { '4a2f3cc3b5e78ddb83dcb426d9863d9d9a723b0337c89dd0b005d89f8d3c05c52b76b29b740f09' }
      let(:cipher1001) { '2ecd8c8a5629d0d02ab457a0fdd0f7b90a192cd46be5ecb6ca570bfc5e268338b1a16cf4ef2d36' }

      it { expect(subject[0].bth).to eq cipher0 }
      it { expect(subject[1].bth).to eq cipher1 }
      it { expect(subject[500].bth).to eq cipher500 }
      it { expect(subject[501].bth).to eq cipher501 }
      it { expect(subject[1000].bth).to eq cipher1000 }
      it { expect(subject[1001].bth).to eq cipher1001 }
    end
  end
end
