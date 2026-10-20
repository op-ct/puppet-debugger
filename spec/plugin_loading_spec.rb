# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'
require 'tmpdir'

describe 'plugin loading' do
  let(:plugins) { PuppetDebugger::InputResponderPlugin.load_plugins }

  it 'returns the built-in plugins' do
    expect(plugins).to include(PuppetDebugger::InputResponders::Commands,
                               PuppetDebugger::InputResponders::Functions,
                               PuppetDebugger::InputResponders::Vars)
  end

  it 'returns only plugin subclasses, sorted by name' do
    expect(plugins).to all(be < PuppetDebugger::InputResponderPlugin)
    expect(plugins.map(&:name)).to eq(plugins.map(&:name).sort)
    expect(plugins.uniq.size).to eq(plugins.size)
  end

  it 'registers a plugin defined after loading' do
    klass = Class.new(PuppetDebugger::InputResponderPlugin)
    begin
      expect(PuppetDebugger::InputResponderPlugin.registry).to include(klass)
    ensure
      PuppetDebugger::InputResponderPlugin.registry.delete(klass)
    end
  end

  it 'finds plugin files on the load path' do
    Dir.mktmpdir do |dir|
      plugin_dir = File.join(dir, 'plugins', 'puppet-debugger', 'input_responders')
      FileUtils.mkdir_p(plugin_dir)
      File.write(File.join(plugin_dir, 'fancy.rb'), <<~RUBY)
        require 'puppet-debugger/input_responder_plugin'
        module PuppetDebugger
          module InputResponders
            class Fancy < InputResponderPlugin
              COMMAND_WORDS = %w[fancy].freeze
              SUMMARY = 'fancy test plugin'
              COMMAND_GROUP = :tools
              def run(_args = [])
                'hello from fancy'
              end
            end
          end
        end
      RUBY
      $LOAD_PATH.unshift(dir)
      begin
        expect(Gem.find_files(PuppetDebugger::InputResponderPlugin::PLUGIN_GLOB))
          .to include(File.join(plugin_dir, 'fancy.rb'))
      ensure
        $LOAD_PATH.delete(dir)
      end
    end
  end
end
