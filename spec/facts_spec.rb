# frozen_string_literal: true

require 'spec_helper'

describe 'facts' do
  let(:debugger) do
    PuppetDebugger::Cli.new(out_buffer: output, use_facterdb: true)
  end

  let(:puppet_version) do
    '8.1'
  end

  let(:facter_version) do
    debugger.default_facter_version
  end

  before(:each) do
    allow(Puppet).to receive(:version).and_return(puppet_version)
  end



  describe '4' do
    before(:each) do
      ENV['DEBUGGER_FACTERDB_FILTER'] = nil
    end
    let(:puppet_version) do
      '4.5.3'
    end
    it 'get node_facts' do
      expect(debugger.node_facts).to be_instance_of(Hash)
    end
    it 'has networking fqdn' do
      expect(debugger.node_facts[:networking]['fqdn']).to eq('foo.example.com')
    end
    it 'has fqdn' do
      expect(debugger.node_facts[:fqdn]).to eq('foo.example.com')
    end
    it 'returns 4' do
      expect(facter_version).to eq('/^4/')
    end
    it 'return default filter' do
      expect(debugger.dynamic_facterdb_filter).to eq("os.name=Rocky and os.release.major=8 and os.architecture=x86_64 and facterversion=/^4/")
    end
  end

  describe 'default facts' do
    describe 'bad filter' do
      before(:each) do
        ENV['DEBUGGER_FACTERDB_FILTER'] = 'facterversion=/^6\.5/'
      end
      it 'return filter' do
        expect(debugger.dynamic_facterdb_filter).to eq('facterversion=/^6\\.5/')
      end
      it 'throws error' do
        expect { debugger.default_facts }.to raise_error(PuppetDebugger::Exception::BadFilter)
      end
    end
    describe 'good filter' do
      before(:each) do
        ENV['DEBUGGER_FACTERDB_FILTER'] = 'facterversion=/^4.0.52/'
      end
      it 'return filter' do
        expect(debugger.dynamic_facterdb_filter).to eq('facterversion=/^4.0.52/')
      end
    end
  end
end
