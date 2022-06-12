# frozen_string_literal: true

source 'https://rubygems.org'

case ENV['DATABASE_ADAPTER']
when 'mongoid' then
  gem 'kaminari-mongoid'
  gem 'mongoid', ENV['MONGOID_VERSION'] || '~> 7.3.0'
  gem 'mongoid-scroll'
when 'activerecord' then
  gem 'activerecord', '~> 5.0.0'
  gem 'otr-activerecord', '~> 1.2.1'
  gem 'virtus'
  gem 'cursor_pagination' # rubocop:disable Bundler/OrderedGems
  gem 'pg'
when nil
  warn "Missing ENV['DATABASE_ADAPTER']."
else
  warn "Invalid ENV['DATABASE_ADAPTER']: #{ENV['DATABASE_ADAPTER']}."
end

gemspec

group :development, :test do
  gem 'bundler'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'fabrication'
  gem 'faker'
  gem 'hyperclient'
  gem 'rack-test'
  gem 'rake'
  gem 'rspec'
  gem 'rubocop', '0.81.0'
  gem 'selenium-webdriver'
  gem 'stripe-ruby-mock', '~> 2.4.1', require: 'stripe_mock'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :test do
  gem 'slack-ruby-danger', '~> 0.1.0', require: false
end
