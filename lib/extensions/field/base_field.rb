
module Protobuf
  module Field
    class BaseField
      def encode_to_stream(value, stream)
        stream << encode(value)
      end

      def decode_from(stream)
        fail NotImplementedError, "#{self.class.name}##{__method__}"
      end
    end
  end
end