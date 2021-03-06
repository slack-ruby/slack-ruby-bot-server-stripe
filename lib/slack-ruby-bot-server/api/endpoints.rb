# frozen_string_literal: true

module SlackRubyBotServer
  module Api
    module Endpoints
      class RootEndpoint
        mount SlackRubyBotServer::Stripe::Api::Endpoints::SubscriptionsEndpoint
      end
    end
  end
end
