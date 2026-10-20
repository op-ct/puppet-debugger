# frozen_string_literal: true

require 'spec_helper'

describe 'PuppetDebugger::Cli.parse_options' do
  def parse(args)
    PuppetDebugger::Cli.parse_options(args)
  end

  it 'has defaults' do
    expect(parse([])).to eq(play: nil, facts: nil, run_once: false, node_name: nil, catalog: nil, quiet: false)
  end

  it 'parses long options' do
    opts = parse(['--play', 'x.pp', '--facts', 'f.json', '--run-once', '--node-name', 'n', '--catalog', 'c.json', '--quiet'])
    expect(opts).to eq(play: 'x.pp', facts: 'f.json', run_once: true, node_name: 'n', catalog: 'c.json', quiet: true)
  end

  it 'parses short options and leaves other arguments' do
    args = ['-q', 'site.pp', '-r']
    expect(parse(args)).to include(quiet: true, run_once: true)
    expect(args).to eq(['site.pp'])
  end

  it 'exits 255 on an unknown option' do
    expect { parse(['--bogus']) }.to raise_error(SystemExit) { |e| expect(e.status).to eq(255) }
  end

  it 'prints help' do
    expect { parse(['--help']) }.to output(/--facts FILE/).to_stdout.and raise_error(SystemExit)
  end
end
