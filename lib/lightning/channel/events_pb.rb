# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: lightning/channel/events.proto

require 'google/protobuf'

require 'lightning/wire/types_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "lightning.channel.events.ChannelCreated" do
    optional :remote_node_id, :string, 1
    optional :is_funder, :uint32, 2
    optional :temporary_channel_id, :string, 3
  end
  add_message "lightning.channel.events.ChannelRestored" do
    optional :remote_node_id, :string, 1
    optional :is_funder, :uint32, 2
    optional :channel_id, :string, 3
  end
  add_message "lightning.channel.events.ChannelIdAssigned" do
    optional :remote_node_id, :string, 1
    optional :temporary_channel_id, :string, 2
    optional :channel_id, :string, 3
  end
  add_message "lightning.channel.events.ShortChannelIdAssigned" do
    optional :channel_id, :string, 1
    optional :short_channel_id, :uint64, 2
  end
  add_message "lightning.channel.events.LocalChannelUpdate" do
    optional :channel_id, :string, 1
    optional :short_channel_id, :uint64, 2
    optional :remote_node_id, :string, 3
  end
  add_message "lightning.channel.events.LocalChannelDown" do
    optional :channel_id, :string, 1
    optional :short_channel_id, :uint64, 2
    optional :remote_node_id, :string, 3
  end
  add_message "lightning.channel.events.ChannelStateChanged" do
    optional :remote_node_id, :string, 1
    optional :previous_state, :string, 2
    optional :current_state, :string, 3
  end
  add_message "lightning.channel.events.ChannelSignatureReceived" do
    optional :channel_id, :string, 1
  end
  add_message "lightning.channel.events.ChannelClosed" do
    optional :channel_id, :string, 1
  end
end

module Lightning
  module Channel
    module Events
      ChannelCreated = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ChannelCreated").msgclass
      ChannelRestored = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ChannelRestored").msgclass
      ChannelIdAssigned = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ChannelIdAssigned").msgclass
      ShortChannelIdAssigned = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ShortChannelIdAssigned").msgclass
      LocalChannelUpdate = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.LocalChannelUpdate").msgclass
      LocalChannelDown = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.LocalChannelDown").msgclass
      ChannelStateChanged = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ChannelStateChanged").msgclass
      ChannelSignatureReceived = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ChannelSignatureReceived").msgclass
      ChannelClosed = Google::Protobuf::DescriptorPool.generated_pool.lookup("lightning.channel.events.ChannelClosed").msgclass
    end
  end
end
