# frozen_string_literal: true

module SlackRubyBotServer
  module Stripe
    module Commands
      class Unsubscribe < SlackRubyBot::Commands::Base
        command 'unsubscribe' do |client, data, match|
          team = ::Team.find(client.owner.id)
          if !team.active_stripe_subscription?
            client.say(channel: data.channel, text: "You don't have a paid subscription, all set.")
            logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user} unsubscribe failed, no subscription"
          elsif data.user == team.activated_user_id
            subscription_info = []
            subscription_id = match['expression']
            active_subscription = team.active_stripe_subscription
            if active_subscription && active_subscription.id == subscription_id
              team.unsubscribe!
              amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
              subscription_info << "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount})."
              logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user}, canceled #{subscription_id}"
            elsif subscription_id
              subscription_info << "Sorry, I cannot find a subscription with \"#{subscription_id}\"."
            else
              subscription_info << "Send \"unsubscribe #{active_subscription.id}\" to confirm."
            end
            client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
            logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user}"
          else
            client.say(channel: data.channel, text: "Sorry, only <@#{team.activated_user_id}> can do that.")
            logger.info "UNSUBSCRIBE: #{client.owner} - #{data.user} unsubscribe failed, not admin"
          end
        end
      end
    end
  end
end
