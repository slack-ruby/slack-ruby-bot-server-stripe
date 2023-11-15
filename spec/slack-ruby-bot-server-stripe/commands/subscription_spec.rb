# frozen_string_literal: true

require 'spec_helper'

describe SlackRubyBotServer::Stripe::Commands::Subscription, vcr: { cassette_name: 'slack/user_info' } do
  let(:app) { SlackRubyBotServer::RealTime::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'subscription' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end
      it 'displays subscribe message' do
        expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message team.trial_text
      end
    end
    context 'with subscribed_at' do
      it 'displays subscription info' do
        customer_info = "Subscriber since #{team.subscribed_at.strftime('%B %d, %Y')}."
        expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message customer_info
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
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end
        it 'displays subscription info' do
          customer_since = Time.at(customer.created).strftime('%B %d, %Y')
          current_period_end = Time.at(team.active_stripe_subscription.current_period_end).strftime('%B %d, %Y')
          subscription_text = [
            "Customer since #{customer_since}.\nSubscribed to Plan ($29.99), will auto-renew on #{current_period_end}.",
            'On file Visa card, Johnny App ending with 4242, expires 9/2018.',
            "Update your credit card info at /subscribe?team_id=#{team.team_id}."
          ].join("\n")
          expect(message: "#{SlackRubyBot.config.user} subscription", user: 'U007').to respond_with_slack_message subscription_text
        end
        context 'past due subscription' do
          before do
            customer.subscriptions.data.first['status'] = 'past_due'
            allow(Stripe::Customer).to receive(:retrieve).and_return(customer)
          end
          it 'displays subscription info' do
            customer_since = Time.at(customer.created).strftime('%B %d, %Y')
            subscription_text = [
              "Customer since #{customer_since}.",
              'Past Due subscription created November 03, 2016 to Plan ($29.99).',
              'On file Visa card, Johnny App ending with 4242, expires 9/2018.',
              "Update your credit card info at /subscribe?team_id=#{team.team_id}."
            ].join("\n")
            expect(message: "#{SlackRubyBot.config.user} subscription", user: 'U007').to respond_with_slack_message subscription_text
          end
        end
        context 'no active subscription' do
          before do
            customer.subscriptions.data = []
            allow(Stripe::Customer).to receive(:retrieve).and_return(customer)
          end
          it 'displays subscription info' do
            customer_since = Time.at(customer.created).strftime('%B %d, %Y')
            subscription_text = [
              "Customer since #{customer_since}.",
              'No active subscriptions.'
            ].join("\n")
            expect(message: "#{SlackRubyBot.config.user} subscription", user: 'U007').to respond_with_slack_message subscription_text
          end
        end
      end
    end
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true, activated_user_id: 'U007') }
    it_behaves_like 'subscription'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      it_behaves_like 'subscription'
    end
  end
end
