# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:all) do
    FactoryBot.reload
    FileUtils.rm_f('tmp/test_node_db')
    FileUtils.rm_f('tmp/test_peer_db')
  end
  config.before(:suite) do
    FactoryBot.find_definitions
  end
  FactoryBot::SyntaxRunner.class_eval do
    include RSpec::Mocks::ExampleMethods
  end
end

class FactoryBotWrapper
  def initialize(instance)
    @instance = instance
  end

  def get
    @instance
  end
end
