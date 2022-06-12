# frozen_string_literal: true

require 'stripe'

require 'slack-ruby-bot-server-rtm'

require_relative 'slack-ruby-bot-server-stripe/version'
require_relative 'slack-ruby-bot-server-stripe/config'
require_relative 'slack-ruby-bot-server-stripe/errors'
require_relative 'slack-ruby-bot-server-stripe/models'
require_relative 'slack-ruby-bot-server-stripe/lifecycle'
require_relative 'slack-ruby-bot-server-stripe/api'
require_relative 'slack-ruby-bot-server-stripe/commands'

SlackRubyBotServer::Config.view_paths << File.expand_path(File.join(__dir__, 'slack-ruby-bot-server-stripe/public'))

require_relative 'slack-ruby-bot-server/api'
