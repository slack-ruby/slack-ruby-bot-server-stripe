require 'spec_helper'

describe SlackRubyBotServer::Stripe do
  let(:team) { Fabricate(:team, activated_user_id: 'activated_user_id') }

  before do
    SlackRubyBotServer::Stripe.configure do |config|
      config.stripe_api_key = 'stripe-api-key'
      config.stripe_api_publishable_key = 'stripe-api-publishable-key'
    end
  end

  after do
    SlackRubyBotServer::Stripe.config.reset!
  end
end
