# frozen_string_literal: true

module Lightning
  module Router
    class RouterState
      class Normal < RouterState
        def next(message, data)
          super(message, data)
        end
      end
    end
  end
end
