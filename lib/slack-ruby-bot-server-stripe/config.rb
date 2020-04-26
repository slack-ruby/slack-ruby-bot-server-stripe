module SlackRubyBotServer
  module Stripe
    module Config
      extend self

      attr_reader :stripe_api_key

      def stripe_api_key=(value)
        @stripe_api_key = value
        ::Stripe.api_key = value
      end

      attr_accessor :stripe_api_publishable_key
      attr_accessor :subscription_plan_id
      attr_accessor :subscription_plan_amount
      attr_accessor :trial_duration
      attr_accessor :root_url

      def reset!
        self.stripe_api_publishable_key = ENV['STRIPE_API_PUBLISHABLE_KEY']
        self.stripe_api_key = ENV['STRIPE_API_KEY']
        self.subscription_plan_id = ENV['STRIPE_SUBSCRIPTION_PLAN_ID']
        self.subscription_plan_amount = -1
        self.root_url = ENV['URL']
        self.trial_duration = 2.weeks
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
