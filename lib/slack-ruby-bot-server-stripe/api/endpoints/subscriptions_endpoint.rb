module SlackRubyBotServer
  module Stripe
    module Api
      module Endpoints
        class SubscriptionsEndpoint < Grape::API
          format :json

          namespace :subscriptions do
            desc 'Create or update a subscription.'
            params do
              requires :stripe_token, type: String
              optional :stripe_token_type, type: String
              optional :stripe_email, type: String
              requires :team_id, type: String
            end
            post do
              begin
                team = Team.where(team_id: params[:team_id]).first || error!('Team Not Found', 404)
                if team.subscribed?
                  SlackRubyBotServer::Api::Middleware.logger.info "Updating a subscription for team #{team}."
                  stripe_customer = team.update_subscription!(params)
                  SlackRubyBotServer::Api::Middleware.logger.info "Updated subscription for team #{team}, stripe_customer_id=#{stripe_customer['id']}."
                else
                  SlackRubyBotServer::Api::Middleware.logger.info "Creating a subscription for team #{team}."
                  stripe_customer = team.subscribe!(params)
                  SlackRubyBotServer::Api::Middleware.logger.info "Subscription for team #{team} created, stripe_customer_id=#{stripe_customer['id']}."
                end
                present team, with: SlackRubyBotServer::Api::Presenters::TeamPresenter
              rescue Errors::AlreadySubscribedError
                error! 'Already Subscribed', 400
              rescue Errors::StripeCustomerExistsError
                error! 'Customer Already Registered', 400
              rescue Errors::NotSubscribedError
                error! 'Not a Subscriber', 400
              rescue Errors::MissingStripeCustomerError
                error! 'Missing Stripe Customer', 400
              end
            end
          end
        end
      end
    end
  end
end
