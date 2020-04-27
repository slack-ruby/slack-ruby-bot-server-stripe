# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    SlackRubyBotServer::Stripe::Config.reset!
  end
end
