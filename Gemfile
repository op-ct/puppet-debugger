# frozen_string_literal: true

source 'http://rubygems.org'
if ENV['USE_OPENVOX']
  gem 'openvox', ENV['PUPPET_GEM_VERSION'] || '~> 8'
else
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 8'
end
#gem 'bolt' if Gem::Version(ENV['PUPPET_GEM_VERSION'])

group :test, :development do
  gem 'bundler'
  gem 'facterdb', '>= 2.0.0'
  gem 'pry'
  gem 'puppet-debugger', path: './'
  gem 'rake', '~> 13.0'
  gem 'rdoc', '~> 6.0'
  gem 'release_me'
  gem 'rspec', '~> 3.6'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
  gem 'simplecov', '>= 0'
end
