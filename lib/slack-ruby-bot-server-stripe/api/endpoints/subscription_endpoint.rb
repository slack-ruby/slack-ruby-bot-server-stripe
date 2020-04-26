module SlackRubyBotServer
  module Stripe
    module Api
      module Endpoints
        class SubscriptionsEndpoint < Grape::API
          format :json

          namespace :subscriptions do
            desc 'Subscribe.'
            params do
              requires :stripe_token, type: String
              requires :stripe_token_type, type: String
              requires :stripe_email, type: String
              requires :team_id, type: String
            end
            post do
              begin
                team = Team.where(team_id: params[:team_id]).first || error!('Team Not Found', 404)
                SlackRubyBotServer::Api::Middleware.logger.info "Creating a subscription for team #{team}."
                stripe_customer = team.subscribe!(params)
                SlackRubyBotServer::Api::Middleware.logger.info "Subscription for team #{team} created, stripe_customer_id=#{stripe_customer['id']}."
                present team, with: SlackRubyBotServer::Api::Presenters::TeamPresenter
              rescue Errors::AlreadySubscribedError
                error! 'Already Subscribed', 400
              rescue Errors::StripeCustomerExistsError
                error! 'Customer Already Registered', 400
              end
            end
          end
        end
      end
    end
  end
end
