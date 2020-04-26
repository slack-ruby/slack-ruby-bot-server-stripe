require 'spec_helper'

describe 'Subscribe', js: true, type: :feature do
  context 'without team_id' do
    before do
      visit '/subscribe'
    end
    it 'requires a team' do
      expect(find('#messages')).to have_text('Missing or invalid team ID.')
      find('#subscribe', visible: false)
    end
  end
  unless ENV['CI']
    context 'stripe' do
      before do
        SlackRubyBotServer::Stripe.configure do |config|
          config.stripe_api_publishable_key = 'pk_test_804U1vUeVeTxBl8znwriXskf'
          config.subscription_plan_id = 'prod_HAd97WaHg4XxNM'
          config.subscription_plan_amount = 3999
        end
      end
      context 'not subscribed' do
        let!(:team) { Fabricate(:team) }
        it 'subscribes team' do
          visit "/subscribe?team_id=#{team.team_id}"
          expect(find('#messages')).to have_text("Subscribe team #{team.name} for $39.99 a year.")

          find('#subscribe', visible: true)

          expect_any_instance_of(Team).to receive(:subscribe!).with(
            hash_including(
              stripe_email: 'foo@bar.com',
              stripe_token_type: 'card',
              stripe_token: /tok.*/,
              team_id: team.team_id
            )
          ).and_return(
            'stripe_customer_id' => 'customer_id'
          )

          find('.stripe-button-el').click

          sleep 1

          stripe_iframe = all('iframe[name=stripe_checkout_app]').last
          Capybara.within_frame stripe_iframe do
            page.find_field('Email').set 'foo@bar.com'
            page.find_field('Card number').set '4242 4242 4242 4242'
            page.find_field('MM / YY').set '12/42'
            page.find_field('CVC').set '123'
            find('button[type="submit"]').click
          end

          sleep 5

          find('#subscribe', visible: false)
          expect(find('#messages')).to have_text("Team #{team.name} successfully subscribed.")
        end
      end
      context 'subscribed' do
        let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: 'stripe-customer-id') }
        it 'updates cc' do
          visit "/subscribe?team_id=#{team.team_id}"
          expect(find('#messages')).to have_text("Update credit card for team #{team.name}.")

          find('.stripe-button-el').click

          sleep 1

          stripe_iframe = all('iframe[name=stripe_checkout_app]').last

          expect_any_instance_of(Team).to receive(:update_subscription!).with(
            hash_including(
              stripe_email: 'foo@bar.com',
              stripe_token_type: 'card',
              stripe_token: /tok.*/,
              team_id: team.team_id
            )
          ).and_return(
            'stripe_customer_id' => 'customer_id'
          )

          Capybara.within_frame stripe_iframe do
            page.find_field('Email').set 'foo@bar.com'
            page.find_field('Card number').set '4012 8888 8888 1881'
            page.find_field('MM / YY').set '12/42'
            page.find_field('CVC').set '345'
            find('button[type="submit"]').click
          end

          sleep 5

          find('#subscribe', visible: false)
          expect(find('#messages')).to have_text("Credit card for team #{team.name} successfully updated.")
        end
      end
    end
  end
end
