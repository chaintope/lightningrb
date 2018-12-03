# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Crypto::ShaChain do
  describe '#generate_from_seed' do
    test_vector =
      [
        {
          seed: '0000000000000000000000000000000000000000000000000000000000000000',
          i: 281_474_976_710_655,
          output: '02a40c85b6f28da08dfdbe0926c53fab2de6d28c10301f8f7c4073d5e42e3148',
        }, {
          seed: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
          i: 281_474_976_710_655,
          output: '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
        }, {
          seed: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
          i: 0xaaaaaaaaaaa,
          output: '56f4008fb007ca9acf0e15b054d5c9fd12ee06cea347914ddbaed70d1c13a528',
        }, {
          seed: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
          i: 0x555555555555,
          output: '9015daaeb06dba4ccc05b91b2f73bd54405f2be9f217fbacd3c5ac2e62327d31',
        }, {
          seed: '0101010101010101010101010101010101010101010101010101010101010101',
          i: 1,
          output: '915c75942a26bb3a433a8ce2cb0427c29ec6c1775cfc78328b57f6ba7bfeaa9c',
        },
      ]
    test_vector.each_with_index do |v, i|
      context "vector - #{i}" do
        subject { described_class.generate_from_seed(v[:seed], v[:i]) }

        it { is_expected.to eq v[:output] }
      end
    end
  end

  # https://github.com/lightningnetwork/lightning-rfc/blob/master/03-transactions.md#storage-tests
  describe '#insert_secret' do
    context 'correct sequence' do
      subject do
        chain = described_class.insert_secret(
          '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          '2273e227a5b7449b6e70f1fb4652864038b1cbf9cd7c043a7d6456b7fc275ad8',
          281_474_976_710_653,
          chain
        )
        chain = described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
        chain = described_class.insert_secret(
          'c65716add7aa98ba7acb236352d665cab17345fe45b55fb879ff80e6bd0c41dd',
          281_474_976_710_651,
          chain
        )
        chain = described_class.insert_secret(
          '969660042a28f32d9be17344e09374b379962d03db1574df5a8a5a47e19ce3f2',
          281_474_976_710_650,
          chain
        )
        chain = described_class.insert_secret(
          'a5a64476122ca0925fb344bdc1854c1c0a59fc614298e50a33e331980a220f32',
          281_474_976_710_649,
          chain
        )
        chain = described_class.insert_secret(
          '05cde6323d949933f7f7b78776bcc1ea6d9b31447732e3802e1f7ac44b650e17',
          281_474_976_710_648,
          chain
        )
        chain
      end

      it 'store without error' do
        expect { subject }.not_to raise_error
      end
    end

    context '#1 incorrect' do
      subject do
        described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
      end

      let(:chain) do
        described_class.insert_secret(
          '02a40c85b6f28da08dfdbe0926c53fab2de6d28c10301f8f7c4073d5e42e3148',
          281_474_976_710_655,
          {}
        )
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#2 incorrect (#1 derived from incorrect)' do
      subject do
        described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '2a40c85b6f28da08dfdbe0926c53fab2de6d28c10301f8f7c4073d5e42e3148',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'dddc3a8d14fddf2b68fa8c7fbad2748274937479dd0f8930d5ebb4ab6bd866a3',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          '2273e227a5b7449b6e70f1fb4652864038b1cbf9cd7c043a7d6456b7fc275ad8',
          281_474_976_710_653,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#3 incorrect' do
      subject do
        described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          'c51a18b13e8527e579ec56365482c62f180b7d5760b46e9477dae59e87ed423a',
          281_474_976_710_653,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#4 incorrect (1,2,3 derived from incorrect)' do
      subject do
        described_class.insert_secret(
          '05cde6323d949933f7f7b78776bcc1ea6d9b31447732e3802e1f7ac44b650e17',
          281_474_976_710_648,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '02a40c85b6f28da08dfdbe0926c53fab2de6d28c10301f8f7c4073d5e42e3148',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'dddc3a8d14fddf2b68fa8c7fbad2748274937479dd0f8930d5ebb4ab6bd866a3',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          'c51a18b13e8527e579ec56365482c62f180b7d5760b46e9477dae59e87ed423a',
          281_474_976_710_653,
          chain
        )
        chain = described_class.insert_secret(
          'ba65d7b0ef55a3ba300d4e87af29868f394f8f138d78a7011669c79b37b936f4',
          281_474_976_710_652,
          chain
        )
        chain = described_class.insert_secret(
          'c65716add7aa98ba7acb236352d665cab17345fe45b55fb879ff80e6bd0c41dd',
          281_474_976_710_651,
          chain
        )
        chain = described_class.insert_secret(
          '969660042a28f32d9be17344e09374b379962d03db1574df5a8a5a47e19ce3f2',
          281_474_976_710_650,
          chain
        )
        chain = described_class.insert_secret(
          'a5a64476122ca0925fb344bdc1854c1c0a59fc614298e50a33e331980a220f32',
          281_474_976_710_649,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#5 incorrect' do
      subject do
        described_class.insert_secret(
          '969660042a28f32d9be17344e09374b379962d03db1574df5a8a5a47e19ce3f2',
          281_474_976_710_650,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          '2273e227a5b7449b6e70f1fb4652864038b1cbf9cd7c043a7d6456b7fc275ad8',
          281_474_976_710_653,
          chain
        )
        chain = described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
        chain = described_class.insert_secret(
          '631373ad5f9ef654bb3dade742d09504c567edd24320d2fcd68e3cc47e2ff6a6',
          281_474_976_710_651,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#6 incorrect (5 derived from incorrect)' do
      subject do
        described_class.insert_secret(
          '05cde6323d949933f7f7b78776bcc1ea6d9b31447732e3802e1f7ac44b650e17',
          281_474_976_710_648,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          '2273e227a5b7449b6e70f1fb4652864038b1cbf9cd7c043a7d6456b7fc275ad8',
          281_474_976_710_653,
          chain
        )
        chain = described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
        chain = described_class.insert_secret(
          '631373ad5f9ef654bb3dade742d09504c567edd24320d2fcd68e3cc47e2ff6a6',
          281_474_976_710_651,
          chain
        )
        chain = described_class.insert_secret(
          'b7e76a83668bde38b373970155c868a653304308f9896692f904a23731224bb1',
          281_474_976_710_650,
          chain
        )
        chain = described_class.insert_secret(
          'a5a64476122ca0925fb344bdc1854c1c0a59fc614298e50a33e331980a220f32',
          281_474_976_710_649,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#7 incorrect' do
      subject do
        described_class.insert_secret(
          '05cde6323d949933f7f7b78776bcc1ea6d9b31447732e3802e1f7ac44b650e17',
          281_474_976_710_648,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          '2273e227a5b7449b6e70f1fb4652864038b1cbf9cd7c043a7d6456b7fc275ad8',
          281_474_976_710_653,
          chain
        )
        chain = described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
        chain = described_class.insert_secret(
          'c65716add7aa98ba7acb236352d665cab17345fe45b55fb879ff80e6bd0c41dd',
          281_474_976_710_651,
          chain
        )
        chain = described_class.insert_secret(
          '969660042a28f32d9be17344e09374b379962d03db1574df5a8a5a47e19ce3f2',
          281_474_976_710_650,
          chain
        )
        chain = described_class.insert_secret(
          'e7971de736e01da8ed58b94c2fc216cb1dca9e326f3a96e7194fe8ea8af6c0a3',
          281_474_976_710_649,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end

    context '#8 incorrect' do
      subject do
        described_class.insert_secret(
          'a7efbc61aac46d34f77778bac22c8a20c6a46ca460addc49009bda875ec88fa4',
          281_474_976_710_648,
          chain
        )
      end

      let(:chain) do
        chain = described_class.insert_secret(
          '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
          281_474_976_710_655,
          {}
        )
        chain = described_class.insert_secret(
          'c7518c8ae4660ed02894df8976fa1a3659c1a8b4b5bec0c4b872abeba4cb8964',
          281_474_976_710_654,
          chain
        )
        chain = described_class.insert_secret(
          '2273e227a5b7449b6e70f1fb4652864038b1cbf9cd7c043a7d6456b7fc275ad8',
          281_474_976_710_653,
          chain
        )
        chain = described_class.insert_secret(
          '27cddaa5624534cb6cb9d7da077cf2b22ab21e9b506fd4998a51d54502e99116',
          281_474_976_710_652,
          chain
        )
        chain = described_class.insert_secret(
          'c65716add7aa98ba7acb236352d665cab17345fe45b55fb879ff80e6bd0c41dd',
          281_474_976_710_651,
          chain
        )
        chain = described_class.insert_secret(
          '969660042a28f32d9be17344e09374b379962d03db1574df5a8a5a47e19ce3f2',
          281_474_976_710_650,
          chain
        )
        chain = described_class.insert_secret(
          'a5a64476122ca0925fb344bdc1854c1c0a59fc614298e50a33e331980a220f32',
          281_474_976_710_649,
          chain
        )
        chain
      end

      it { expect { subject }.to raise_error(RuntimeError) }
    end
  end

  describe '#derive_old_secret' do
    let(:seed) { 'FF' * 32 }
    let(:secrets) do
      ((2**48 - 10)...2**48).to_a.reverse.map { |i| described_class.generate_from_seed(seed, i) }
    end
    let(:chain) do
      chain = {}
      ((2**48 - 10)...2**48).reverse_each.with_index do |i, index|
        chain = described_class.insert_secret(secrets[index], i, chain)
      end
      chain
    end

    describe 'return same value as generate_from_seed' do
      ((2**48 - 10)...2**48).reverse_each.with_index do |i, index|
        it { expect(described_class.derive_old_secret(i, chain)).to eq secrets[index] }
      end
    end
  end
end
