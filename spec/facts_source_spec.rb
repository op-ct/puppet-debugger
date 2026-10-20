# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe 'facts sources' do
  let(:output) { StringIO.new }
  let(:options) { {} }
  let(:debugger) { PuppetDebugger::Cli.new({ out_buffer: output }.merge(options)) }
  let(:values) { { 'os' => { 'name' => 'Zed', 'family' => 'Test' }, 'networking' => { 'fqdn' => 'z.example.com' } } }

  def with_facts_file(content, ext)
    Tempfile.create(['facts', ext]) do |f|
      f.write(content)
      f.flush
      yield f.path
    end
  end

  describe 'use_facterdb?' do
    around do |example|
      saved = ENV['DEBUGGER_FACTERDB_FILTER']
      begin
        example.run
      ensure
        ENV['DEBUGGER_FACTERDB_FILTER'] = saved
      end
    end

    it 'is true when a filter is in the environment' do
      ENV['DEBUGGER_FACTERDB_FILTER'] = 'facterversion=/^4/'
      expect(debugger.use_facterdb?).to be true
    end

    it 'is false without a filter or option' do
      ENV.delete('DEBUGGER_FACTERDB_FILTER')
      expect(debugger.use_facterdb?).to be false
    end

    context 'with use_facterdb false' do
      let(:options) { { use_facterdb: false } }

      it 'is false even with a filter' do
        ENV['DEBUGGER_FACTERDB_FILTER'] = 'facterversion=/^4/'
        expect(debugger.use_facterdb?).to be false
      end
    end
  end

  describe 'facts file' do
    it 'reads a plain JSON facts hash' do
      with_facts_file(values.to_json, '.json') do |path|
        dbg = PuppetDebugger::Cli.new(out_buffer: output, facts: path)
        expect(dbg.node.facts.values['os']['name']).to eq('Zed')
        expect(dbg.node.facts.name).to eq('z.example.com')
      end
    end

    it 'reads Puppet facts documents' do
      doc = { 'name' => 'doc.example.com', 'values' => values }
      with_facts_file(doc.to_json, '.json') do |path|
        dbg = PuppetDebugger::Cli.new(out_buffer: output, facts: path)
        expect(dbg.node.facts.values['os']['family']).to eq('Test')
      end
    end

    it 'reads YAML' do
      with_facts_file(values.to_yaml, '.yaml') do |path|
        dbg = PuppetDebugger::Cli.new(out_buffer: output, facts: path)
        expect(dbg.node.facts.values['os']['name']).to eq('Zed')
      end
    end

    it 'takes precedence over facterdb' do
      with_facts_file(values.to_json, '.json') do |path|
        dbg = PuppetDebugger::Cli.new(out_buffer: output, facts: path, use_facterdb: true)
        expect(dbg.node.facts.values['os']['name']).to eq('Zed')
      end
    end

    it 'reports a bad file' do
      with_facts_file('not json', '.json') do |path|
        expect { PuppetDebugger::Cli.new(out_buffer: output, facts: path).node }
          .to raise_error(PuppetDebugger::Exception::BadFactsFile, /#{Regexp.escape(path)}/)
      end
    end

    it 'reports a missing file' do
      expect { PuppetDebugger::Cli.new(out_buffer: output, facts: '/nonexistent/facts.json').node }
        .to raise_error(PuppetDebugger::Exception::BadFactsFile)
    end
  end

  describe 'without facterdb installed' do
    let(:options) { { use_facterdb: true } }

    it 'names the gem and the install command' do
      allow_any_instance_of(PuppetDebugger::Cli).to receive(:load_facterdb).and_return(false)
      expect { debugger.node }.to raise_error(PuppetDebugger::Exception::FacterDBNotInstalled, /gem install.*facterdb/)
    end
  end

  describe 'local facts' do
    let(:options) { { use_facterdb: false } }

    it 'come from this machine' do
      expect(debugger.node.facts.values).to have_key('os')
      expect(debugger.node.facts.values['networking']['fqdn']).not_to eq('foo.example.com')
    end

    it 'are gathered once per process' do
      debugger.node
      expect(Puppet::Node::Facts.indirection).not_to receive(:find)
      PuppetDebugger::Cli.new(out_buffer: output, use_facterdb: false).node
    end
  end
end
