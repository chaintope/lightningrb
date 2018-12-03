# frozen_string_literal: true

require 'json'

class ::Object
  def build_json
    if is_a?(Array)
      "[#{map { |o| JSON.generate(o.to_h) }.join(',')}]"
    else
      JSON.generate(to_h)
    end
  end
end
