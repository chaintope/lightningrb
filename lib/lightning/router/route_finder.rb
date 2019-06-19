# frozen_string_literal: true

require 'dijkstraruby'

module Lightning
  module Router
    module RouteFinder
      # @param source String public key
      # @param target String public key
      # @param updates Hash whose key is ChannelDesc and value is ChannelUpdate
      # @param assisted_routes Array of public keys
      # @param assisted_channels Array of short_channel_id
      # @return
      def self.find(source, target, updates, _assisted_routes, assisted_channels)
        routes = updates.map do |k, _v|
          [k[:a], k[:b], 1]
        end
        assisted_channels.map do |short_channel_id|
          key = updates.select { |k, _v| k[:id] == short_channel_id }.keys.first
          routes << [key[:a], key[:b], 0] if key
        end
        graph = Dijkstraruby::Graph.new(routes)
        result = graph.shortest_path(source, target)
        raise Lightning::Exceptions::RouteNotFound.new(source, target) if result[1] == Float::INFINITY
        paths = result[0]
        hops = paths.map.with_index do |pubkey, index|
          next unless paths[index + 1]
          [pubkey, paths[index + 1]]
        end.compact

        hops.map do |hop|
          desc = updates.select { |k, _v| (k[:a] == hop[0] && k[:b] == hop[1])||(k[:a] == hop[1] && k[:b] == hop[0]) }.keys.first
          next unless desc
          Lightning::Router::Messages::Hop[hop[0], hop[1], updates[desc]]
        end.compact
      end
    end
  end
end
