module SlackRubyBotServer
  module Api
    module Presenters
      module RootPresenter
        link :subscriptions do |opts|
          "#{base_url(opts)}/api/subscriptions"
        end
      end
    end
  end
end
