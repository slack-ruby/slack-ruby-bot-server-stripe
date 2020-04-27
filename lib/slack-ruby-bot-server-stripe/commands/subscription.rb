module SlackRubyBotServer
  module Stripe
    module Commands
      class Subscription < SlackRubyBot::Commands::Base
        command 'subscription' do |client, data, _match|
          team = ::Team.find(client.owner.id)
          include_admin_info = (data.user == team.activated_user_id)
          client.say(channel: data.channel, text: team.subscription_text(include_admin_info: include_admin_info))
          logger.info "SUBSCRIPTION: #{client.owner} - #{data.user}"
        end
      end
    end
  end
end
