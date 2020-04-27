# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Stripe::Commands::Unsubscribe, vcr: { cassette_name: 'slack/user_info' } do
  let(:app) { SlackRubyBotServer::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'unsubscribe' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end
      it 'displays all set message' do
        expect(message: "#{SlackRubyBot.config.user} unsubscribe").to respond_with_slack_message "You don't have a paid subscription, all set."
      end
    end
    context 'with subscribed_at' do
      before do
        team.update_attributes!(subscribed: true, subscribed_at: 1.year.ago)
      end
      it 'displays subscription info' do
        expect(message: "#{SlackRubyBot.config.user} unsubscribe").to respond_with_slack_message "You don't have a paid subscription, all set."
      end
    end
    context 'with a plan' do
      include_context :stripe_mock
      before do
        stripe_helper.create_plan(id: 'slack-playplay-yearly', amount: 2999, name: 'Plan')
      end
      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'slack-playplay-yearly',
            email: 'foo@bar.com'
          )
        end
        before do
          team.update_attributes!(
            subscribed: true,
            stripe_customer_id: customer['id'],
            activated_user_id: 'u-activated-user-id'
          )
        end
        let(:active_subscription) { team.active_stripe_subscription }
        let(:current_period_end) { Time.at(active_subscription.current_period_end).strftime('%B %d, %Y') }
        it 'displays unsubscribe info' do
          subscription_text = "Send \"unsubscribe #{active_subscription['id']}\" to confirm."
          expect(message: "#{SlackRubyBot.config.user} unsubscribe", user: 'u-activated-user-id').to respond_with_slack_message subscription_text
        end
        it 'cannot unsubscribe with an invalid subscription id' do
          expect(message: "#{SlackRubyBot.config.user} unsubscribe xyz", user: 'u-activated-user-id').to respond_with_slack_message 'Sorry, I cannot find a subscription with "xyz".'
        end
        it 'unsubscribes' do
          expect(message: "#{SlackRubyBot.config.user} unsubscribe #{active_subscription.id}", user: 'u-activated-user-id').to respond_with_slack_message 'Successfully canceled auto-renew for Plan ($29.99).'
          team.reload
          expect(team.subscribed).to be false
          expect(team.stripe_customer_id).to be nil
        end
        context 'not an admin' do
          it 'cannot unsubscribe' do
            expect(message: "#{SlackRubyBot.config.user} unsubscribe xyz").to respond_with_slack_message "Sorry, only <@#{team.activated_user_id}> can do that."
          end
        end
      end
    end
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    before do
      team.update_attributes!(activated_user_id: 'u-activated-user-id')
    end
    it_behaves_like 'unsubscribe'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      it_behaves_like 'unsubscribe'
    end
  end
end
