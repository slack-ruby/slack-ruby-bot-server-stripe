module SlackRubyBotServer
  module Stripe
    module Config
      extend self

      attr_accessor :stripe_api_key
      attr_accessor :stripe_api_publishable_key
      attr_accessor :subscription_amount_in_cents
      attr_accessor :additional_merge_fields
      attr_accessor :subscription_plan_id

      def reset!
        self.stripe_api_publishable_key = ENV['STRIPE_API_PUBLISHABLE_KEY']
        self.stripe_api_key = ENV['STRIPE_API_KEY']
        self.subscription_amount_in_cents = ENV['STRIPE_SUBSCRIPTION_AMOUNT']
        self.subscription_plan_id = ENV['STRIPE_SUBSCRIPTION_PLAN_ID']
      end

      reset!
    end

    class << self
      def configure
        block_given? ? yield(Config) : Config
      end

      def config
        Config
      end
    end
  end
end
