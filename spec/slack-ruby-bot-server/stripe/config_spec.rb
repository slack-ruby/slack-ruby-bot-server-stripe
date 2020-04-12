require 'spec_helper'

describe SlackRubyBotServer::Stripe::Config do
  context 'stripe_api_key' do
    context 'with stripe_api_key set' do
      before do
        SlackRubyBotServer::Stripe.configure do |config|
          config.stripe_api_key = 'set'
        end
      end
      it 'sets Stripe.api_key' do
        expect(SlackRubyBotServer::Stripe.config.stripe_api_key).to eq 'set'
        expect(Stripe.api_key).to eq 'set'
      end
    end
    context 'without stripe_api_key set' do
      it 'defaults Stripe.api_key to nil' do
        expect(Stripe.api_key).to be nil
      end
    end
    context 'with ENV[STRIPE_API_KEY] set' do
      before do
        allow(ENV).to receive(:[]) { |k| "#{k} was set" }
        SlackRubyBotServer::Stripe.config.reset!
      end
      it 'sets Stripe.api_key' do
        expect(SlackRubyBotServer::Stripe.config.stripe_api_key).to eq 'STRIPE_API_KEY was set'
        expect(Stripe.api_key).to eq 'STRIPE_API_KEY was set'
      end
    end
  end
  %i[
    stripe_api_publishable_key
    subscription_plan_id
    trial_duration
    root_url
  ].each do |k|
    context "with #{k} set" do
      before do
        SlackRubyBotServer::Stripe.configure do |config|
          config.send("#{k}=", 'set')
        end
      end
      it "sets and returns #{k}" do
        expect(SlackRubyBotServer::Stripe.config.send(k)).to eq 'set'
      end
    end
  end
end
