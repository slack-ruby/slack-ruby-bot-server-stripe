# frozen_string_literal: true

require 'timecop'

RSpec.configure do |config|
  config.after do
    Timecop.return
  end
end
