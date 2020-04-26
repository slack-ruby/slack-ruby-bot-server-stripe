SlackRubyBotServer::Config.service_class.instance.on :starting do |team|
  begin
    team.check_stripe!
  rescue StandardError => e
    SlackRubyBotServer::Service.logger.error e
  end
end

SlackRubyBotServer::Config.service_class.instance.every :day do
  Team.each do |team|
    begin
      team.check_stripe!
    rescue StandardError => e
      SlackRubyBotServer::Service.logger.error e
    end
  end
end
