# frozen_string_literal: true

module Lightning
  module Utils
    class Serializer
      attr_accessor :fields

      def initialize
        @fields = []
      end

      def list(type: nil)
        raise 'type is required' if type.nil?
        fields << List.new(type)
        self
      end

      def char
        fields << Char.new
        self
      end

      def uint16
        fields << UInt16.new
        self
      end

      def uint32
        fields << UInt32.new
        self
      end

      def uint64
        fields << UInt64.new
        self
      end

      def binary(bytes)
        fields << Binary.new(bytes)
        self
      end

      def hex(bytes)
        fields << Hex.new(bytes)
        self
      end

      def pascal_string
        fields << PascalString.new
        self
      end

      def public_key
        fields << PublicKey.new
        self
      end

      def private_key
        fields << PrivateKey.new
        self
      end

      def bitcoin_key
        fields << BitcoinKey.new
        self
      end

      def x(n)
        raise 'n should be > 1' if n < 2
        raise 'field not found' if fields.empty?
        last_field = fields.last
        (n - 1).times { fields << last_field }
        self
      end

      def then(type)
        fields << Type.new(type)
        self
      end

      def to_binary(*args)
        fields.map do |f|
          f.pack(args.shift)
        end.join('')
      end

      def to_a(payload)
        values = []
        rest = fields.inject(payload) do |p, f|
          value, rest = f.unpack(p)
          values << value
          rest
        end
        [values, rest]
      end

      class Type
        def initialize(type)
          @type = type
        end

        def unpack(payload)
          @type.unpack(payload)
        end

        def pack(value)
          @type.pack(value)
        end
      end

      class List
        def initialize(type)
          @type = type
        end

        def unpack(payload)
          return [[], ''] if payload.bytesize == 2
          len, rest = payload.unpack('na*')
          values = []
          len.times do |i|
            value, rest = @type.unpack(rest)
            values << value
          end
          [values, rest]
        end

        def pack(value)
          [value.length].pack('n') + value.map { |v| @type.pack(v) }.join('')
        end
      end

      class Char
        def unpack(payload)
          payload.unpack('Ca*')
        end

        def pack(value)
          [value].pack('C')
        end
      end

      class UInt16
        def unpack(payload)
          payload.unpack('na*')
        end

        def pack(value)
          [value].pack('n')
        end
      end

      class UInt32
        def unpack(payload)
          payload.unpack('Na*')
        end

        def pack(value)
          [value].pack('N')
        end
      end

      class UInt64
        def unpack(payload)
          payload.unpack('q>a*')
        end

        def pack(value)
          [value].pack('q>')
        end
      end

      class Binary
        attr_accessor :bytes
        def initialize(bytes)
          @bytes = bytes
        end

        def unpack(payload)
          payload.unpack("a#{bytes}a*")
        end

        def pack(value)
          [value].pack('a*')
        end
      end

      class Hex
        attr_accessor :bytes
        def initialize(bytes)
          @bytes = bytes
        end

        def unpack(payload)
          payload.unpack("H#{bytes * 2}a*")
        end

        def pack(value)
          [value].pack('H*')
        end
      end

      class PascalString
        def unpack(payload)
          return ['', ''] if payload.bytesize == 2
          len, rest = payload.unpack('na*')
          rest.unpack("H#{len * 2}a*")
        end

        def pack(value)
          [value.htb.bytesize, value.htb].pack('na*')
        end
      end

      class PublicKey
        def unpack(payload)
          payload.unpack("H66a*")
        end

        def pack(value)
          [value].pack('H66')
        end
      end

      class PrivateKey
        def unpack(payload)
          payload.unpack("H64a*")
        end

        def pack(value)
          [value].pack('H64')
        end
      end

      class BitcoinKey
        def unpack(payload)
          private_key, rest = payload.unpack("H64a*")
          [Bitcoin::Key.new(priv_key: private_key), rest]
        end

        def pack(value)
          [value.priv_key].pack('H64')
        end
      end
    end
  end
end
