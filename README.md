Slack Ruby Bot Server Stripe Extension
======================================

[![Gem Version](https://badge.fury.io/rb/slack-ruby-bot-server-stripe.svg)](https://badge.fury.io/rb/slack-ruby-bot-server-stripe)
[![Build Status](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-stripe.svg?branch=master)](https://travis-ci.org/slack-ruby/slack-ruby-bot-server-stripe)

A model extension to [slack-ruby-bot-server](https://github.com/slack-ruby/slack-ruby-bot-server) that enables trials and paid subscriptions for your bots using [Stripe](https://stripe.com).

### Sample

See [slack-ruby/slack-ruby-bot-server-stripe-sample](https://github.com/slack-ruby/slack-ruby-bot-server-stripe-sample) for a working sample.

### Usage

#### Gemfile

Add 'slack-ruby-bot-server-stripe' to Gemfile.

```ruby
gem 'slack-ruby-bot-server-stripe'
```

#### Configure

Configure your app, typically via `config/initializers/slack_ruby_bot_server_stripe.rb`.

```ruby
SlackRubyBotServer::Stripe.configure do |config|
  config.stripe_api_key = ENV['STRIPE_API_KEY'] # Stripe API key
  config.stripe_api_publishable_key = ENV['STRIPE_API_PUBLISHABLE_KEY'] # Stripe publishable API key
  config.subscription_plan_id = ENV['STRIPE_SUBSCRIPTION_PLAN_ID'] # Stripe subscription plan ID
  config.trial_duration = 2.weeks # Trial duration
  config.root_url = ENV['URL'] || 'http://localhost:5000' # Bot root of subscription info links
end
```

By default the configuration will use the values in the environment variables above.

#### Database Schema

Define additional fields on your database.

##### Mongoid

Additional fields from [models/mongoid.rb](lib/slack-ruby-bot-server-stripe/models/mongoid.rb) are automatically included.

##### ActiveRecord

Add migrations for additional fields from [activerecord/schema.rb](spec/database_adapters/activerecord/schema.rb).

#### Implement Callbacks

Use callbacks together with default `_text` methods to communicate subscription life cycle to your users. These are typically added by creating `lib/models/team.rb`.

```ruby
class Team
  before_trial_expiring do
    inform!(text: trial_text)
  end

  after_subscribed do
    inform!(text: subscribed_text)
  end

  after_unsubscribed do
    inform!(text: unsubscribed_text)
  end

  after_subscription_expired do
    inform!(text: subscription_expired_text)
  end

  after_subscription_past_due do
    inform!(text: subscription_past_due_text)
  end

  private

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: token)
  end

  def slack_channels
    slack_client.channels_list(
      exclude_archived: true,
      exclude_members: true
    )['channels'].select do |channel|
      channel['is_member']
    end
  end

  def inform!(message)
    slack_channels.each do |channel|
      message_with_channel = message.merge(channel: channel['id'], as_user: true)
      slack_client.chat_postMessage(message_with_channel)
    end
  end
end
```

#### Add Trial Link

Your bot's help command should display trial text and subscription link. This is typically done in `lib/commands/help.rb`.

```ruby
class Help < SlackRubyBot::Commands::Base
  HELP = <<-EOS.freeze
```
Sample bot.

General
-------

help               - get this helpful message

```
EOS

  def self.call(client, data, _match)
    client.say(channel: data.channel, text: [
      HELP,
      client.owner.reload.subscribed? ? nil : client.owner.trial_text
    ].compact.join("\n"))

    client.say(channel: data.channel, gif: 'help')
  end
end
```

### Attributes

This library adds the following public attributes to the `Team` class.

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

### Methods

The following public methods are added to `Team`.

#### trial_text

A message about the remaining trial period. Will raise an error if a team is subscribed.

e.g. `Your trial subscription expires in 3 days. Subscribe your team at https://example.com?team_id=id.`

#### subscribed_text

A message upon successful subscription.

e.g. `Your team has been subscribed.`

#### unsubscribed_text

A message to use when unsubscribed.

e.g. `Your team has been unsubscribed. Subscribe your team at https://example.com?team_id=id.`

#### subscription_expired_text

A message to use upon subscription expiration.

e.g. `Your subscription has expired. Subscribe your team at https://example.com?team_id=id.`

#### subscription_past_due_text

A message to use when paid subscription is past due.

e.g. `Your subscription is past due. Update your credit card info at https://example.com?update_cc?team_id=id.`

#### trial_expired?

True if number of remaining trial days is zero. Will raise an error if a team is subscribed.

#### remaining_trial_days

Number of days remaining in the trial. Will raise an error if a team is subscribed.

#### subscription_expired?

Returns `true` when the trial period has ended and/or a subscription has expired.

#### tags

A set of tags to support other extensions, such as [slack-ruby-bot-server-mailchimp](https://github.com/slack-ruby/slack-ruby-bot-server-mailchimp). Possible values are `subscribed`, `trial` and `paid`.

#### active_stripe_subscription

An active Stripe subscription, if any.

#### active_stripe_subscription?

Returns `true` if the team has an active Stripe subscription.

#### subscription_text(params)

Returns detailed subscription info or a trial message, typically used in a bot command.

Pass `include_admin_info: true` to include detailed credit card on file information.

#### subscribe!(params)

Creates and returns a Stripe customer. Updates subscription fields. Invokes `subscribed` callbacks.

Parameters are `stripe_token`, `stripe_email` and an optional `subscription_plan_id`.

#### unsubscribe!

Marks a Stripe subscription to be terminated at period end. Invokes `unsubscribed` callbacks.

#### update_subscription!(params)

Updates a Stripe customer.

Parameters are `stripe_token` for the new payment instrument.

### Lifecycle Methods

The following methods are invoked before a team is started and from a daily lifecycle cron via `Team#check_stripe!`.

#### check_subscription!

Invoked for subscribed teams, unsubscribes teams that have canceled subscriptions or past due payments.

#### check_trials!

Invoked for teams during trial. Notify teams that their trial is about to expire.

### API Endpoints

This extension adds the following API endpoints.

#### POST /subscriptions

Creates or updates a subscription for a team, using a payment method tokenized by Stripe. See [subscription_endpoint.rb](lib/slack-ruby-bot-server-stripe/api/endpoints/subscription_endpoint.rb) for details.

### HTML Views

#### /subscribe

This extension adds a [subscription page](slack-ruby-bot-server-stripe/public/subscribe.html.erb) that handles initial subscriptions and credit card updates. Clone the page into your own project's `public/subscribe.html.erb` to customize.

### Slack Commands

This extension adds the following Slack commands.

#### subscription

Displays current subscription information, see [subscription.rb](lib/slack-ruby-bot-server-stripe/commands/subscription.rb). This command also displays partial credit card information to the user that has installed the bot.

#### unsubscribe

Turns off auto-renew for the current subscription, see [unsubscribe.rb](lib/slack-ruby-bot-server-stripe/commands/unsubscribe.rb). This command will only succeed when run by the user that has installed the bot.

### Copyright & License

Copyright [Daniel Doubrovkine](http://code.dblock.org) and Contributors, 2019-2020

[MIT License](LICENSE)
