module SlackRubyBotServer
  module Stripe
    module Errors
      class StripeCustomerExistsError < StandardError; end
      class MissingStripeCustomerError < StandardError; end
      class AlreadySubscribedError < StandardError; end
      class NotSubscribedError < StandardError; end
    end
  end
end
