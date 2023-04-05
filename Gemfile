# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in outboxable.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "rubocop", "~> 1.21"

group :development, :test do
  gem "sidekiq", "~> 7.0", require: true
  gem "sidekiq-cron", "~> 1.10"
  gem "activesupport", "~> 7.0"
end

