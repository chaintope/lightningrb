# frozen_string_literal: true

module Lightning
  module Utils
    module Algebrick
      # Either = ::Algebrick.type(:value_type1, :value_type2) do
      #   variants  type(:value_type1) { fields value: :value_type1  },
      #             type(:value_type2) { fields value: :value_type2  }
      #   # fields right: type, left: type
      # end
      class ::Object
        include Algebrick::Types
      end
    end
  end
end
