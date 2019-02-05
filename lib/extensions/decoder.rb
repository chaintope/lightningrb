# frozen_string_literal: true

module Protobuf
  class Message
    module Serialization
      def decode_from(stream)
        self.class.all_fields.each do |field|
          if field.repeated?
            len = stream.read(2).unpack('n').first
            value = []
            len.times do |i|
              value << field.decode_from(stream)
            end
          else
            value = field.decode_from(stream)
          end
          __send__("#{field.name}=", value)
        end
        self
      end
    end
  end
end
