# frozen_string_literal: true

module Protobuf
  class Encoder
    def self.encode(message, stream)
      message.each_field do |field, value|
        if field.repeated?
          if field.packed?
            packed_value = value.map { |val| field.encode(val) }.join
            stream << packed_value
          else
            stream << [value.length].pack('n')
            value.each do |val|
              field.encode_to_stream(val, stream)
            end
          end
        else
          field.encode_to_stream(value, stream)
        end
      end

      stream
    end
  end
end
