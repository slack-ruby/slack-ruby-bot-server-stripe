Slack Ruby Bot Server Stripe Extension
=========================================

[![Gem Version](https://badge.fury.io/rb/slack-ruby-bot-server-stripe.svg)](https://badge.fury.io/rb/slack-ruby-bot-server-stripe)
[![Build Status](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-stripe.svg?branch=master)](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-stripe)

A lifecycle extension to [slack-ruby-bot-server](https://github.com/slack-ruby/slack-ruby-bot-server) that enables paid subscriptions for your bots using [Stripe](https://stripe.com).

### Usage

Add 'slack-ruby-bot-server-stripe' to Gemfile.

```ruby
gem 'slack-ruby-bot-server-stripe'
```

Configure.

```ruby
SlackRubyBotServer::Stripe.configure do |config|
  config.stripe_api_key = ENV['STRIPE_API_KEY'] # Stripe API key
  config.stripe_api_publishable_key = ENV['STRIPE_API_PUBLISHABLE_KEY'] # Stripe publishable API key
  config.subscription_plan_id = ENV['STRIPE_SUBSCRIPTION_PLAN_ID'] # Stripe subscription plan ID
  config.subscription_amount_in_cents = ENV['STRIPE_SUBSCRIPTION_AMOUNT'] # Stripe subscription amount in cents
end
```

By default the configuration will use the values in the environment variables above.

TODO

### Copyright & License

Copyright [Daniel Doubrovkine](http://code.dblock.org) and Contributors, 2019

[MIT License](LICENSE)
