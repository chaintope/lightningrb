# frozen_string_literal: true

module Protobuf
  module Field
    class Uint64Field < VarintField
      def encode_to_stream(value, stream)
        stream << [value].pack('q>')
      end

      def decode_from(stream)
        return if stream.eof?
        stream.read(8).unpack('q>').first
      end
    end
  end
end
