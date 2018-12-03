# frozen_string_literal: true

module Lightning
  module Utils
    class Binary

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

      def to_b(*args)
        fields.map do |f|
          f.pack(args.shift)
        end.join('')
      end

      def to_a(payload)
        values = []
        fields.inject(payload) do |rest, f|
          value, rest = f.unpack(rest)
          values << value
          rest
        end
        values
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
          values
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

      class PascalString
        def unpack(payload)
          return ['', ''] if payload.bytesize == 2
          len, rest = payload.unpack('na*')
          rest.unpack("a#{len}a*")
        end

        def pack(value)
          [value.bytesize, value].pack('na*')
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
    end
  end
end