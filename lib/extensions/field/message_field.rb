# frozen_string_literal: true

module Protobuf
  module Field
    class MessageField < BaseField
      def encode(value)
        value.encode
      end

      def decode_from(stream)
        return if stream.eof?
        type_class.decode_from(stream)
      end
    end
  end
end
