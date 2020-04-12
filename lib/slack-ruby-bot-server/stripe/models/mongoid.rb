require_relative 'methods'

module SlackRubyBotServer
  module Stripe
    module Models
      module Mongoid
        extend ActiveSupport::Concern
        include Methods

        included do
          field :stripe_customer_id, type: String
          field :subscribed, type: Boolean, default: false
          field :subscribed_at, type: DateTime
          field :subscription_expired_at, type: DateTime
          field :trial_informed_at, type: DateTime

          scope :striped, -> { where(subscribed: true, :stripe_customer_id.ne => nil) }
          scope :trials, -> { where(subscribed: false) }
        end
      end
    end
  end
end

Team.include SlackRubyBotServer::Stripe::Models::Mongoid
