# frozen_string_literal: true

require_relative 'lib/puppet-debugger/version'

Gem::Specification.new do |s|
  s.name = 'puppet-debugger'
  s.version = PuppetDebugger::VERSION
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|resources|local_test_results|pec)/}) }
  s.bindir        = 'bin'
  s.executables = %w[pdb puppet-debugger]
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.require_paths = ['lib']
  s.authors = ['Corey Osman']
  s.description = 'A interactive command line tool for evaluating and debugging the puppet language'
  s.email = 'corey@nwops.io'
  s.extra_rdoc_files = [
    'CHANGELOG.md',
    'LICENSE.txt',
    'README.md'
  ]
  # Ruby 2.7 is the oldest Ruby shipped with a supported Puppet (7); no Ruby 3 syntax is used
  s.required_ruby_version = '>= 2.7'
  s.homepage = 'https://gitlab.com/puppet-debugger/puppet-debugger'
  s.licenses = ['MIT']
  s.rubygems_version = '2.4.5.1'
  s.summary = 'A repl based debugger for the puppet language'
  # No runtime dependencies: the debugger uses only Ruby's standard library and the
  # puppet or openvox gem, which is not declared because either one satisfies it
  # (puppet >= 7 or openvox >= 8). Keep it that way; see README "Installation".
  s.add_development_dependency('facterdb', ['>= 2.0.0'])
  s.add_development_dependency('rdoc', ['>= 6.0'])
  s.add_development_dependency('rspec', ['>= 3.6'])
end
