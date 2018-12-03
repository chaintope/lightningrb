# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Utils::Serializer do
  describe 'encode/decode intger' do
    let(:builder) { described_class.new.char.uint16.uint32.uint64 }
    let(:payload) { '7b0001000000020000000000000003'.htb }
    let(:array) { [123, 1, 2, 3] }
    let(:rest) { '01'.htb }

    it do
      expect(builder.to_a(payload + rest)[0]).to eq array
      expect(builder.to_a(payload + rest)[1]).to eq rest
      expect(builder.to_binary(*array)).to eq payload
    end
  end

  describe 'encode/decode string and key' do
    let(:builder) { described_class.new.hex(2).pascal_string.public_key.private_key }
    let(:payload) do
      '010100010a023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe' \
      '436f54eb30ff4956bbdd3222d44cc5e8a1261dab1e07957bdac5ae88fe3261ef' \
      '321f3749'.htb
    end
    let(:array) do
      [
        "0101",
        "0a",
        '023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb',
        '30ff4956bbdd3222d44cc5e8a1261dab1e07957bdac5ae88fe3261ef321f3749',
      ]
    end
    let(:rest) { '01'.htb }

    it do
      expect(builder.to_a(payload + rest)[0]).to eq array
      expect(builder.to_a(payload + rest)[1]).to eq rest
      expect(builder.to_binary(*array)).to eq payload
    end
  end

  describe 'encode/decode nested object' do
    class NestedClass
      attr_accessor :a, :b
      def initialize(a, b)
        @a = a
        @b = b
      end

      def self.builder
        Lightning::Utils::Serializer.new.uint64.uint64
      end

      def self.unpack(payload)
        args = builder.to_a(payload)
        [new(*(args[0])), args[1]]
      end

      def self.pack(value)
        NestedClass.builder.to_binary(value.a, value.b)
      end

      def ==(other)
        a == other.a && b == other.b
      end
    end

    let(:builder) { described_class.new.uint64.then(NestedClass).list(type: NestedClass) }
    let(:payload) do
      '00000000000000030000000000000001000000000000000200020000000000000001000000000000000200000000000000010000000000000002'.htb
    end
    let(:nested) { NestedClass.new(1, 2) }
    let(:array) { [3, nested, [nested, nested]] }

    it do
      expect(builder.to_a(payload)[0]).to eq array
      expect(builder.to_a(payload)[1]).to eq ''
      expect(builder.to_binary(*array)).to eq payload
    end
  end
end
