# frozen_string_literal: true

require_relative 'models/methods'
require_relative "models/#{::SlackRubyBotServer::Config.database_adapter}.rb"
