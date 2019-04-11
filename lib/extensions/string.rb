# frozen_string_literal: true

class String
  def camel
    split('_').map { |w| w[0].upcase + w[1..-1] }.join
  end

  def snake
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .downcase
  end
end
