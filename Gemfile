# frozen_string_literal: true

source 'http://rubygems.org'
gem 'awesome_print', '~> 1.9'
gem 'facterdb', '>= 2.0.0'
gem 'pluginator', '~> 1.5.0'
gem 'rb-readline'
gem 'table_print'
gem 'tty-pager'
if ENV['USE_OPENVOX']
  gem 'openvox', git: 'https://github.com/OpenVoxProject/puppet.git', ref: ENV['PUPPET_GEM_VERSION'] || '8.15.0'
else
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 8'
end
#gem 'bolt' if Gem::Version(ENV['PUPPET_GEM_VERSION'])

group :test, :development do
  gem 'bundler'
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
