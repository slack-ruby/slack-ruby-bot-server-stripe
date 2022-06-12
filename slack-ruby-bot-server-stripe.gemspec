# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slack-ruby-bot-server-stripe/version'

Gem::Specification.new do |spec|
  spec.name          = 'slack-ruby-bot-server-stripe'
  spec.version       = SlackRubyBotServer::Stripe::VERSION
  spec.authors       = ['Daniel Doubrovkine']
  spec.email         = ['dblock@dblock.org']

  spec.summary       = 'Stripe extension for slack-ruby-bot-server.'
  spec.homepage      = 'https://github.com/slack-ruby/slack-ruby-bot-server-stripe'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.require_paths = ['lib']

  spec.add_dependency 'slack-ruby-bot-server-rtm'
  spec.add_dependency 'stripe', '~> 1.58.0'
end
