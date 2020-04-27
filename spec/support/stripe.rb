# frozen_string_literal: true

require 'stripe_mock'

RSpec.shared_context :stripe_mock do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before do
    StripeMock.start
  end

  after do
    StripeMock.stop
  end
end

RSpec.shared_context :subscribed_team do
  include_context :stripe_mock

  let(:team) { Fabricate(:team) }

  let(:customer) do
    Stripe::Customer.create(
      source: stripe_helper.generate_card_token,
      plan: 'yearly',
      email: 'user@example.com'
    )
  end

  before do
    stripe_helper.create_plan(id: 'yearly', amount: 2999, name: 'Plan')
    team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
  end
end
