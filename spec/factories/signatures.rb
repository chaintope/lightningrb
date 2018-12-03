# frozen_string_literal: true

FactoryBot.define do
  factory(:signature, class: 'String') do
    initialize_with do
      '304402203b5969880d01a90c34ea3999eb78e6bd476603db6bd0ba96742a3e60' \
      '0b0eaebc022000aa488c80e8e949452b471bc6d5f15e48bd10c8b4cb1c3f7e76' \
      'a55d68643725'
    end
  end
end
