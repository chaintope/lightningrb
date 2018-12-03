module Protobuf
  class Message
    module Serialization
      def decode_from(stream)
        self.class.all_fields.each do |field|
          value = field.decode_from(stream)
          __send__("#{field.name}=", value)
        end
        self
      end
    end
  end
end
