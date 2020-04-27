# frozen_string_literal: true

module SlackRubyBotServer
  module Api
    module Presenters
      module TeamPresenter
        property :subscribed, type: Boolean, desc: 'Team is a paid subscriber.'
        property :subscribed_at, type: DateTime, desc: 'Date/time when a subscription was purchased.'
      end
    end
  end
end
