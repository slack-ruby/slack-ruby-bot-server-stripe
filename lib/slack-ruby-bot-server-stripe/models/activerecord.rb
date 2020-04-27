# frozen_string_literal: true

require_relative 'methods'

module SlackRubyBotServer
  module Stripe
    module Models
      module ActiveRecord
        extend ActiveSupport::Concern
        include Methods

        included do
          # TODO
        end
      end
    end
  end
end

Team.include SlackRubyBotServer::Stripe::Models::ActiveRecord
