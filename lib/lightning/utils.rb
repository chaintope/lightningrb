# frozen_string_literal: true

module Lightning
  module Utils
    autoload :Algebrick, 'lightning/utils/algebrick'
    autoload :Serializer, 'lightning/utils/serializer'
    autoload :LexicographicalOrdering, 'lightning/utils/lexicographical_ordering'
  end
end

require 'lightning/utils/logging'
