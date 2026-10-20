# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'

describe PuppetDebugger::Formatter::Color do
  around do |example|
    saved = Puppet[:color]
    begin
      Puppet[:color] = 'ansi'
      example.run
    ensure
      Puppet[:color] = saved
    end
  end

  let(:text) { "{\n  'name' => 'web01',\n  'port' => 80,\n  'owner' => undef,\n  'on' => true,\n  'ref' => File['/tmp/x']\n}" }
  let(:colored) { described_class.apply(text) }

  it 'colours strings, numbers, undef, booleans and type names' do
    expect(colored).to include("\e[0;33m'web01'\e[0m")
    expect(colored).to include("\e[0;34m80\e[0m")
    expect(colored).to include("\e[0;31mundef\e[0m")
    expect(colored).to include("\e[0;32mtrue\e[0m")
    expect(colored).to include("\e[0;36mFile\e[0m[\e[0;33m'/tmp/x'\e[0m]")
  end

  it 'leaves punctuation and layout alone' do
    expect(colored.gsub(/\e\[[0-9;]*m/, '')).to eq(text)
  end

  it 'passes inspect fallbacks through untouched' do
    expect(described_class.apply('#<Sensitive [value redacted]>')).to eq('#<Sensitive [value redacted]>')
  end

  it 'returns text that does not lex unchanged' do
    expect(described_class.apply("'unterminated")).to eq("'unterminated")
  end

  it 'keeps escaped quotes aligned' do
    src = %q('it\'s "quoted"')
    expect(described_class.apply(src)).to eq("\e[0;33m#{src}\e[0m")
  end

  it 'does nothing when color is off' do
    Puppet[:color] = false
    expect(described_class.apply(text)).to eq(text)
  end
end
