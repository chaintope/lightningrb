# frozen_string_literal: true

module Lightning
  module Wire
    module Serialization
      def load(payload)
        decode(payload)
      end

      def to_payload
        stream = StringIO.new
        Protobuf::Encoder.encode(self, stream)
        stream.string
      end
    end
  end
end
