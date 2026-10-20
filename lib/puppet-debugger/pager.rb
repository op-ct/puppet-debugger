# frozen_string_literal: true

require 'io/console'

module PuppetDebugger
  # Sends long output through an external pager, the way `git log` does.
  # The pager command comes from the PAGER environment variable and defaults
  # to `less -R`, which passes ANSI colour through. Paging only happens when
  # the output is a terminal; otherwise, or if the pager cannot be started,
  # the text is written to the output unchanged.
  class Pager
    DEFAULT_COMMAND = 'less -R'
    DEFAULT_HEIGHT = 24

    attr_reader :output

    # @param output [IO] where output goes when not paging
    # @param enabled [Boolean] false disables paging entirely
    def initialize(output: $stdout, enabled: true)
      @output = output
      @enabled = enabled
    end

    # @return [Integer] the terminal height in lines, from the console,
    #   the LINES environment variable, or 24
    def self.height
      rows = IO.console.winsize.first if IO.console
      rows = ENV['LINES'].to_i if rows.nil? || rows < 1
      rows < 1 ? DEFAULT_HEIGHT : rows
    end

    # @return [String] the pager command line
    def command
      cmd = ENV['PAGER'].to_s.strip
      cmd.empty? ? DEFAULT_COMMAND : cmd
    end

    # @return [Boolean] true when paging is enabled and the output is a tty
    def enabled?
      @enabled && output.respond_to?(:tty?) && output.tty?
    end

    # @param text [String] the content to display
    # @summary pages the text when enabled, else writes it to the output
    def page(text)
      return output.write(text) unless enabled?

      IO.popen(command, 'w') { |pipe| pipe.write(text) }
    rescue Errno::ENOENT, Errno::EPIPE
      output.write(text)
    end
  end
end
