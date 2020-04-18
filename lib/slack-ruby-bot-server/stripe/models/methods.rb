module SlackRubyBotServer
  module Stripe
    module Models
      module Methods
        extend ActiveSupport::Concern
        extend ActiveModel::Callbacks

        included do
          define_model_callbacks :trial_expiring, :subscription_expired, :unsubscribed
          define_model_callbacks :subscribed, only: [:after]
          before_validation :update_subscribed_at
          before_validation :update_subscription_expired_at
          after_update :subscribed!
        end

        # supports https://github.com/slack-ruby/slack-ruby-bot-server-mailchimp
        def tags
          [
            subscribed? ? 'subscribed' : 'trial',
            stripe_customer_id? ? 'paid' : nil
          ].compact
        end

        def subscription_expired?
          return false if subscribed?
          return true if subscription_expired_at

          time_limit = Time.now - trial_duration
          created_at < time_limit
        end

        def subscription_text(options = { include_admin_info: false })
          subscription_text = []
          if active_stripe_subscription?
            subscription_text << stripe_customer_text
            subscription_text.concat(stripe_customer_subscriptions_info)
            if options[:include_admin_info]
              subscription_text.concat(stripe_customer_invoices_info)
              subscription_text.concat(stripe_customer_sources_info)
              subscription_text << update_cc_text
            end
          elsif subscribed && subscribed_at
            subscription_text << subscriber_text
          else
            subscription_text << trial_text
          end
          subscription_text.compact.join("\n")
        end

        # params:
        # - stripe_token
        # - stripe_email
        # - subscription_plan_id
        def subscribe!(params)
          raise Errors::AlreadySubscribedError if subscribed?
          raise Errors::StripeCustomerExistsError if stripe_customer_id

          customer = ::Stripe::Customer.create(
            source: params[:stripe_token],
            plan: params[:subscription_plan_id] || SlackRubyBotServer::Stripe.config.subscription_plan_id,
            email: params[:stripe_email],
            metadata: {
              id: _id,
              team_id: team_id,
              name: name,
              domain: domain
            }
          )

          update_attributes!(
            subscribed: true,
            subscribed_at: Time.now.utc,
            stripe_customer_id: customer['id']
          )

          customer
        end

        def unsubscribe!
          raise Errors::NotSubscribedError unless subscribed?
          raise Errors::MissingStripeCustomerError unless active_stripe_subscription?

          run_callbacks :unsubscribed do
            active_stripe_subscription.delete(at_period_end: true)
          end
        end

        def active_stripe_subscription?
          !active_stripe_subscription.nil?
        end

        def active_stripe_subscription
          return unless stripe_customer

          stripe_customer.subscriptions.detect do |subscription|
            subscription.status == 'active' && !subscription.cancel_at_period_end
          end
        end

        def trial_ends_at
          raise Errors::AlreadySubscribedError if subscribed?

          created_at + trial_duration
        end

        def remaining_trial_days
          raise Errors::AlreadySubscribedError if subscribed?

          [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
        end

        def trial_text
          raise Errors::AlreadySubscribedError if subscribed?

          [
            remaining_trial_days.zero? ?
              'Your trial subscription has expired.' :
              "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}.",
            subscribe_text
          ].join(' ')
        end

        def unsubscribed_text
          [
            'Your team has been unsubscribed.',
            subscribe_text
          ].join(' ')
        end

        def subscribed_text
          'Your team has been subscribed.'
        end

        def subscription_expired_text
          [
            'Your subscription has expired.',
            subscribe_text
          ].join(' ')
        end

        private

        def subscription_expired!
          return unless subscription_expired?
          return if subscription_expired_at

          run_callbacks :subscription_expired do
            # use subscribe_text to tell users to (re)subscribe
            update_attributes!(subscription_expired_at: Time.now.utc)
          end
        end

        def update_cc_text
          "Update your credit card info at #{root_url}/update_cc?team_id=#{team_id}."
        end

        def trial_expiring?
          return false if subscribed? || subscription_expired?
          return false if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)

          true
        end

        def trial_expiring!
          return unless trial_expiring?

          run_callbacks :trial_expiring do
            # use trial_text to inform users
            update_attributes!(trial_informed_at: Time.now.utc)
          end
        end

        def stripe_customer
          return unless stripe_customer_id

          @stripe_customer ||= ::Stripe::Customer.retrieve(stripe_customer_id)
        end

        def stripe_customer_text
          "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
        end

        def subscriber_text
          return unless subscribed_at

          "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}."
        end

        unless respond_to?(:subscribe_text)
          def subscribe_text
            "Subscribe your team at #{root_url}/subscribe?team_id=#{team_id}."
          end
        end

        def trial_duration
          SlackRubyBotServer::Stripe.config.trial_duration
        end

        def root_url
          SlackRubyBotServer::Stripe.config.root_url
        end

        def stripe_customer_subscriptions_info
          stripe_customer.subscriptions.map do |subscription|
            amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
            "Subscribed to #{subscription.plan.name} (#{amount}), will#{subscription.cancel_at_period_end ? ' not' : ''} auto-renew on #{current_period_end}."
          end
        end

        def stripe_auto_renew?
          stripe_customer.subscriptions.any? do |subscription|
            !subscription.cancel_at_period_end
          end
        end

        def stripe_customer_invoices_info
          stripe_customer.invoices.map do |invoice|
            amount = ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)
            "Invoice for #{amount} on #{Time.at(invoice.date).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
          end
        end

        def stripe_customer_sources_info
          stripe_customer.sources.map do |source|
            "On file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
          end
        end

        def subscribed!
          return unless subscribed? && subscribed_changed?

          run_callbacks :subscribed do
            # use subscribed_text to inform users
          end
        end

        def update_subscribed_at
          return unless subscribed? && subscribed_changed?

          self.subscribed_at = subscribed? ? DateTime.now.utc : nil
        end

        def update_subscription_expired_at
          return unless subscribed? && subscription_expired_at?

          self.subscription_expired_at = nil
        end
      end
    end
  end
end
