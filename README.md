Slack Ruby Bot Server Stripe Extension
======================================

[![Gem Version](https://badge.fury.io/rb/slack-ruby-bot-server-stripe.svg)](https://badge.fury.io/rb/slack-ruby-bot-server-stripe)
[![Build Status](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-stripe.svg?branch=master)](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-stripe)

A model extension to [slack-ruby-bot-server](https://github.com/slack-ruby/slack-ruby-bot-server) that enables trials and paid subscriptions for your bots using [Stripe](https://stripe.com).

### Usage

#### Gemfile

Add 'slack-ruby-bot-server-stripe' to Gemfile.

```ruby
gem 'slack-ruby-bot-server-stripe'
```

#### Configure

```ruby
SlackRubyBotServer::Stripe.configure do |config|
  config.stripe_api_key = ENV['STRIPE_API_KEY'] # Stripe API key
  config.stripe_api_publishable_key = ENV['STRIPE_API_PUBLISHABLE_KEY'] # Stripe publishable API key
  config.subscription_plan_id = ENV['STRIPE_SUBSCRIPTION_PLAN_ID'] # Stripe subscription plan ID
  config.trial_duration = 2.weeks # Trial duration
  config.root_url = ENV['URL'] # Bot root of subscription info links
end
```

By default the configuration will use the values in the environment variables above.

#### Implement Team Methods

##### inform_everyone!(message)

TODO: refactor into callbacks

Implement `Team#inform_everyone!(message = {})` that sends a Slack message to your team during trial expiration and on a successful subscription.

##### subscribe_text

TODO: refactor into config

Subscription call out message.

##### subscribed_text

TODO: refactor into config

Subscribed call out message.

### Attributes

This extension adds the following public attributes to `Team`.

#### stripe_customer_id

Stripe customer string ID.

#### subscribed

Boolean whether the team is subscribed.

When set without a Stripe customer ID creates a perpetual subscription.

#### subscription_expired_at

Timestamp for when a subscription has expired.

#### trial_informed_at

Timestamp for when the team was informed of a pending end of trial.

#### trial_ends_at

Timestamp for when the trial ends. Will raise an error if a team is subscribed.

#### trial_message

A message about the remaining trial period. Will raise an error if a team is subscribed.

#### remaining_trial_days

Number of days remaining in the trial. Will raise an error if a team is subscribed.

### Team Methods

This extension adds the following public methods to `Team`.

#### subscription_expired?

Returns `true` when the trial period has ended and/or a subscription has expired.

#### tags

A set of tags to support other extensions, such as [slack-ruby-bot-server-mailchimp](https://github.com/slack-ruby/slack-ruby-bot-server-mailchimp). Possible values are `subscribed`, `trial` and `paid`.

#### active_stripe_subscription

An active Stripe subscription, if any.

#### active_stripe_subscription?

Returns `true` if the team has an active Stripe subscription.

#### subscription_info(params)

Returns detailed subscription info or a trial message.

Pass `include_admin_info: true` to include detailed credit card on file information.

#### subscribe!(params)

Creates and returns a Stripe customer. Updates subscription fields.

Parameters are `stripe_token`, `stripe_email` and an optional `subscription_plan_id`.

#### unsubscribe!

Marks a Stripe subscription to be terminated at period end.

### Copyright & License

Copyright [Daniel Doubrovkine](http://code.dblock.org) and Contributors, 2019-2020

[MIT License](LICENSE)
