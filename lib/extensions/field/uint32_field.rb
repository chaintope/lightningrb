# frozen_string_literal: true

module Protobuf
  module Field
    class Uint32Field < VarintField
      def encode_to_stream(value, stream)
        stream <<
          case get_option('.lightning.wire.bits')
          when 24 then [value].pack('N')[1..-1]
          when 16 then [value].pack('n')
          when 8 then  [value].pack('C')
          else [value].pack('N')
          end
      end

      def decode_from(stream)
        return if stream.eof?
        case get_option('.lightning.wire.bits')
        when 24 then stream.read(3).unpack("C3").inject(0){|sum, c| sum = (sum << 8) + c}
        when 16 then stream.read(2).unpack('n').first
        when 8 then  stream.read(1).unpack('C').first
        else stream.read(4).unpack('N').first
        end
      end
    end
  end
end
