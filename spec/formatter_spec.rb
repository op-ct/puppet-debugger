# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'

describe PuppetDebugger::Formatter do
  let(:output) { StringIO.new }
  let(:debugger) { PuppetDebugger::Cli.new(out_buffer: output) }

  def fmt(value)
    described_class.format(value)
  end

  it 'renders scalars in Puppet syntax' do
    expect(fmt('blah')).to eq("'blah'")
    expect(fmt(42)).to eq('42')
    expect(fmt(nil)).to eq('undef')
    expect(fmt(true)).to eq('true')
  end

  it 'renders collections one key per line with sorted string keys' do
    expect(fmt({ 'b' => [1, 2], :a => nil })).to eq("{\n  'a' => undef,\n  'b' => [1, 2]\n}")
    expect(fmt([])).to eq('[]')
    expect(fmt({})).to eq('{}')
  end

  it 'renders types and resource references' do
    expect(fmt(Puppet::Pops::Types::TypeFactory.range(1, 10))).to eq('Integer[1, 10]')
    expect(fmt(Puppet::Pops::Types::TypeFactory.resource('File', '/tmp/x'))).to eq("File['/tmp/x']")
  end

  it 'redacts Sensitive values' do
    expect(fmt(Puppet::Pops::Types::PSensitiveType::Sensitive.new('pw'))).to include('redacted')
    expect(fmt(Puppet::Pops::Types::PSensitiveType::Sensitive.new('pw'))).not_to include('pw')
  end

  describe 'RAL resources' do
    let(:ral) do
      type = debugger.parser.evaluate_string(debugger.scope, "notify{'ff:gg': message => 'hi'}").first
      debugger.scope.catalog.resource(type.type_name, type.title).to_ral
    end

    it 'renders the class name and parameters' do
      text = fmt(ral)
      expect(text).to start_with('Puppet::Type::Notify {')
      expect(text).to include("'title' => 'ff:gg'")
      expect(text).to include("'message' => 'hi'")
      expect(text).to include("'loglevel' => 'notice'")
    end

    it 'renders a compiler resource through the RAL' do
      ral # evaluates the manifest that adds the resource to the catalog
      resource = debugger.scope.catalog.resource('Notify', 'ff:gg')
      expect(resource).to be_a(Puppet::Parser::Resource)
      expect(fmt(resource)).to include("'message' => 'hi'")
    end

    it 'renders a list of resources one per entry with class names' do
      text = fmt([ral, ral])
      expect(text).to start_with("[\n  Puppet::Type::Notify {")
      expect(text.scan('Puppet::Type::Notify').size).to eq(2)
      expect(text).to include("'title' => 'ff:gg'")
    end

    it 'renders resources nested deeper as hashes' do
      expect(fmt({ 'r' => ral })).to include("'title' => 'ff:gg'")
    end
  end

  it 'renders facts objects as their values' do
    facts = Puppet::Node::Facts.new('x', 'os' => { 'name' => 'Rocky' })
    expect(fmt(facts)).to eq("{\n  'os' => {\n    'name' => 'Rocky'\n  }\n}")
  end

  it 'renders Bolt objects through to_data' do
    stub_const('Bolt::Result', Struct.new(:value) do
      def to_data
        { 'value' => value }
      end
    end)
    expect(fmt(Bolt::Result.new('ok'))).to eq("{\n  'value' => 'ok'\n}")
  end

  it 'falls back to inspect for other objects' do
    expect(fmt(Object.new)).to match(/#<Object/)
  end
end
