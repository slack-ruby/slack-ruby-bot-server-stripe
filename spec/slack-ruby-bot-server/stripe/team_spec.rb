require 'spec_helper'

describe SlackRubyBotServer::Stripe::Models do
  context '.stripe_customer_id' do
    let(:team) { Fabricate(:team) }
    it 'defaults to nil' do
      expect(team.stripe_customer_id).to be nil
    end
  end
  context '#subscription_expired!' do
    let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
    before do
      expect(team).to receive(:inform_everyone!).with(text: "Subscribe your team at /subscribe?team_id=#{team.team_id}.")
      team.send(:subscription_expired!)
    end
    it 'sets subscription_expired_at' do
      expect(team.subscription_expired_at).to_not be nil
    end
    context '(re)subscribed' do
      before do
        expect(team).to receive(:inform_everyone!).with(text: 'Your team has been subscribed.')
        team.update_attributes!(subscribed: true)
      end
      it 'resets subscription_expired_at' do
        expect(team.subscription_expired_at).to be nil
      end
    end
  end
  context 'subscribed states' do
    let(:today) { DateTime.parse('2018/7/15 12:42pm') }
    let(:subscribed_team) { Fabricate(:team, subscribed: true) }
    let(:team_created_today) { Fabricate(:team, created_at: today) }
    let(:team_created_1_week_ago) { Fabricate(:team, created_at: (today - 1.week)) }
    let(:team_created_3_weeks_ago) { Fabricate(:team, created_at: (today - 3.weeks)) }
    before do
      Timecop.travel(today + 1.day)
    end
    it 'subscription_expired?' do
      expect(subscribed_team.subscription_expired?).to be false
      expect(team_created_1_week_ago.subscription_expired?).to be false
      expect(team_created_3_weeks_ago.subscription_expired?).to be true
    end
    it 'trial_ends_at' do
      expect { subscribed_team.send(:trial_ends_at) }.to raise_error SlackRubyBotServer::Stripe::Errors::AlreadySubscribedError
      expect(team_created_today.send(:trial_ends_at)).to eq team_created_today.created_at + 2.weeks
      expect(team_created_1_week_ago.send(:trial_ends_at)).to eq team_created_1_week_ago.created_at + 2.weeks
      expect(team_created_3_weeks_ago.send(:trial_ends_at)).to eq team_created_3_weeks_ago.created_at + 2.weeks
    end
    it 'remaining_trial_days' do
      expect { subscribed_team.send(:remaining_trial_days) }.to raise_error SlackRubyBotServer::Stripe::Errors::AlreadySubscribedError
      expect(team_created_today.send(:remaining_trial_days)).to eq 13
      expect(team_created_1_week_ago.send(:remaining_trial_days)).to eq 6
      expect(team_created_3_weeks_ago.send(:remaining_trial_days)).to eq 0
    end
    context '#inform_trial!' do
      it 'subscribed' do
        expect(subscribed_team).to_not receive(:inform_everyone!)
        subscribed_team.send(:inform_trial!)
      end
      it '1 week ago' do
        expect(team_created_1_week_ago).to receive(:inform_everyone!).with(
          text: "Your trial subscription expires in 6 days. #{team_created_1_week_ago.send(:subscribe_text)}"
        )
        team_created_1_week_ago.send(:inform_trial!)
      end
      it 'expired' do
        expect(team_created_3_weeks_ago).to_not receive(:inform_everyone!)
        team_created_3_weeks_ago.send(:inform_trial!)
      end
      it 'informs once' do
        expect(team_created_1_week_ago).to receive(:inform_everyone!).once
        2.times { team_created_1_week_ago.send(:inform_trial!) }
      end
    end
  end
  context '#subscription_info' do
    let(:team) { Fabricate(:team) }
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end
      it 'returns trial message' do
        expect(team.subscription_info).to eq "Your trial subscription expires in 14 days. Subscribe your team at /subscribe?team_id=#{team.team_id}."
      end
    end
    context 'with subscribed_at' do
      before do
        allow(team).to receive(:inform_everyone!)
        team.update_attributes!(subscribed: true)
      end
      it 'returns subscription info' do
        expect(team.subscription_info).to eq "Subscriber since #{team.subscribed_at.strftime('%B %d, %Y')}."
      end
    end
    context 'with a plan' do
      include_context :stripe_mock
      before do
        stripe_helper.create_plan(id: 'yearly', amount: 2999, name: 'Plan')
      end
      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'yearly',
            email: 'user@example.com'
          )
        end
        before do
          allow(team).to receive(:inform_everyone!)
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end
        let(:card) { customer.sources.first }
        let(:current_period_end) { Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y') }
        let(:customer_info) do
          [
            "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
            "Subscribed to Plan ($29.99), will auto-renew on #{current_period_end}."
          ]
        end
        let(:credit_card_info) do
          [
            "On file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}.",
            "Update your credit card info at /update_cc?team_id=#{team.team_id}."
          ]
        end
        it 'returns subscription_info with admin info' do
          expect(team.subscription_info(include_admin_info: true)).to eq [
            customer_info,
            credit_card_info
          ].join("\n")
        end
        it 'returns subscription_info without admin info' do
          expect(team.subscription_info).to eq customer_info.join("\n")
        end
      end
    end
  end
  context '#subscribe!' do
    context 'subscribed team' do
      let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: 'customer_id') }
      it 'fails to create a subscription' do
        expect do
          team.subscribe!(
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'user@example.com'
          )
        end.to raise_error SlackRubyBotServer::Stripe::Errors::AlreadySubscribedError
      end
    end
    context 'non-subscribed team with a customer_id' do
      let!(:team) { Fabricate(:team, stripe_customer_id: 'customer_id') }
      it 'fails to create a subscription' do
        expect do
          team.subscribe!(
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'user@example.com'
          )
        end.to raise_error SlackRubyBotServer::Stripe::Errors::StripeCustomerExistsError
      end
    end
    context 'new team' do
      let!(:team) { Fabricate(:team) }
      it 'creates a subscription' do
        expect(Stripe::Customer).to receive(:create).with(
          source: 'token',
          plan: 'yearly',
          email: 'user@example.com',
          metadata: {
            id: team._id,
            team_id: team.team_id,
            name: team.name,
            domain: team.domain
          }
        ).and_return('id' => 'customer_id')
        expect_any_instance_of(Team).to receive(:inform_everyone!).once
        team.subscribe!(
          stripe_token: 'token',
          stripe_token_type: 'card',
          stripe_email: 'user@example.com',
          subscription_plan_id: 'yearly'
        )
        team.reload
        expect(team.subscribed).to be true
        expect(team.subscribed_at).to_not be nil
        expect(team.stripe_customer_id).to eq 'customer_id'
      end
    end
  end
  context '#unsubscribe!' do
    let(:team) { Fabricate(:team) }
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end
      it 'displays all set message' do
        expect { team.unsubscribe! }.to raise_error SlackRubyBotServer::Stripe::Errors::NotSubscribedError
      end
    end
    context 'with subscribed_at' do
      before do
        allow(team).to receive(:inform_everyone!)
        team.update_attributes!(subscribed: true, subscribed_at: 1.year.ago)
      end
      it 'cannot unsubscribe without a stripe customer' do
        expect { team.unsubscribe! }.to raise_error SlackRubyBotServer::Stripe::Errors::MissingStripeCustomerError
      end
    end
    context 'with a plan' do
      include_context :stripe_mock
      before do
        stripe_helper.create_plan(id: 'yearly', amount: 2999, name: 'Plan')
      end
      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'yearly',
            email: 'user@example.com'
          )
        end
        before do
          allow(team).to receive(:inform_everyone!)
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end
        let(:active_subscription) { team.active_stripe_subscription }
        let(:current_period_end) { Time.at(active_subscription.current_period_end).strftime('%B %d, %Y') }
        it 'cancels auto-renew' do
          expect(team.send(:stripe_auto_renew?)).to be true
          team.unsubscribe!
          team.reload
          expect(team.subscribed).to be true
          expect(team.stripe_customer_id).to_not be nil
          expect(team.send(:stripe_auto_renew?)).to be false
        end
      end
    end
  end
end
