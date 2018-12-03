
module Protobuf
  module Field
    class MessageField < BaseField
      def encode(value)
        value.encode
      end

      def decode_from(stream)
        unless stream.eof?
          type_class.decode_from(stream)
        end
      end
    end
  end
end