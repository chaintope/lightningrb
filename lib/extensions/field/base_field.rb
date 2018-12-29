# frozen_string_literal: true

module Protobuf
  module Field
    class BaseField
      def encode_to_stream(value, stream)
        stream << encode(value)
      end

      def decode_from(_stream)
        raise NotImplementedError.new("#{self.class.name}##{__method__}")
      end
    end
  end
end
