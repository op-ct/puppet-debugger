# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger/pager'
require 'tempfile'

describe PuppetDebugger::Pager do
  # StringIO that claims to be a terminal, so paging is attempted
  let(:tty_io) do
    io = StringIO.new
    io.define_singleton_method(:tty?) { true }
    io
  end
  let(:text) { "line one\nline two\n" }

  around do |example|
    saved = ENV['PAGER']
    begin
      example.run
    ensure
      ENV['PAGER'] = saved
    end
  end

  it 'reports a positive height' do
    expect(described_class.height).to be_a(Integer)
    expect(described_class.height).to be > 0
  end

  it 'defaults the command to less -R' do
    ENV.delete('PAGER')
    expect(described_class.new.command).to eq('less -R')
  end

  it 'takes the command from PAGER' do
    ENV['PAGER'] = 'more'
    expect(described_class.new.command).to eq('more')
  end

  it 'writes to the output when disabled' do
    pager = described_class.new(output: tty_io, enabled: false)
    pager.page(text)
    expect(tty_io.string).to eq(text)
  end

  it 'writes to the output when the output is not a tty' do
    out = StringIO.new
    described_class.new(output: out).page(text)
    expect(out.string).to eq(text)
  end

  it 'pipes the text through the pager command' do
    Tempfile.create('pager') do |f|
      ENV['PAGER'] = "cat > #{f.path}"
      described_class.new(output: tty_io).page(text)
      expect(File.read(f.path)).to eq(text)
      expect(tty_io.string).to be_empty
    end
  end

  it 'falls back to the output when the pager cannot start' do
    ENV['PAGER'] = '/nonexistent/pager'
    described_class.new(output: tty_io).page(text)
    expect(tty_io.string).to eq(text)
  end
end
