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
