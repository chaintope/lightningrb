# frozen_string_literal: true

module Lightning
  module Utils
    class BlockGenerator < Concurrent::Actor::Context

      require 'jsonclient'

      def initialize(setting)
        reference << :generate
        @client = JSONClient.new
        @setting = setting
        @client.debug_dev = STDOUT
        @client.set_auth(setting[:domain], setting[:username], setting[:password])
      end

      def on_message(message)
        case message
        when :generate
          begin
            @client.post(@setting[:endpoint], {'method': 'generatetoaddress','params': [1, @setting[:coinbase_address]]})  
          rescue => e
            log(Logger::WARN, e.message)
          end
          reference.perform_later(:generate, delayed: 10)
        end
      end
    end
  end
end
