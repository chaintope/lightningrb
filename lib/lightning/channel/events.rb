# frozen_string_literal: true

require 'lightning/channel/events_pb'

module Lightning
  module Channel
    module Events
      class ChannelCreated
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class ChannelRestored
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class ChannelIdAssigned
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class ShortChannelIdAssigned
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class LocalChannelUpdate
        attr_accessor :channel, :channel_announcement, :channel_update
        def self.build(channel, channel_announcement, channel_update, fields = {})
          new(fields).tap do |e|
            e.channel = channel
            e.channel_announcement = channel_announcement
            e.channel_update = channel_update
          end
        end
      end

      class LocalChannelDown
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class ChannelStateChanged
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class ChannelSignatureReceived
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end

      class ChannelClosed
        attr_accessor :channel
        def self.build(channel, fields = {})
          new(fields).tap {|e| e.channel = channel }
        end
      end
    end
  end
end
