# frozen_string_literal: true

FactoryBot.define do
  factory(:globalfeatures, class: 'String') do
    initialize_with { new("01") }
  end
  factory(:localfeatures, class: 'String') do
    initialize_with { new("0003") }
  end
end
