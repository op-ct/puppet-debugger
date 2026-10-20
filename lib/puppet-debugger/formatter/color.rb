# frozen_string_literal: true

require 'puppet'
require 'puppet/pops'
require 'puppet/util/colors'

module PuppetDebugger
  module Formatter
    # Colours text produced by Formatter.format. The text is Puppet literal
    # syntax, so Puppet's own lexer finds the tokens, and each token kind gets a
    # colour through Puppet::Util::Colors, which honours the `color` setting
    # (ansi, html or false). Anything the lexer does not tokenize, such as the
    # `#<...>` fallback for objects, is left as it is, and text that does not
    # lex is returned unchanged.
    module Color
      extend Puppet::Util::Colors

      TOKEN_COLORS = {
        STRING: :yellow, DQPRE: :yellow, DQMID: :yellow, DQPOST: :yellow,
        NUMBER: :blue,
        UNDEF: :red,
        BOOLEAN: :green,
        CLASSREF: :cyan
      }.freeze

      # @param text [String] output from Formatter.format
      # @return [String] the same text with colour codes around literals
      def self.apply(text)
        lexer = Puppet::Pops::Parser::Lexer2.new
        lexer.lex_string(text)
        out = String.new
        pos = 0
        lexer.fullscan.each do |symbol, token|
          next unless token.respond_to?(:offset) # the scan ends with [false, false]

          offset = token.offset
          out << text.byteslice(pos...offset) if offset > pos
          literal = text.byteslice(offset, token.length)
          color = TOKEN_COLORS[symbol]
          out << (color ? colorize(color, literal) : literal)
          pos = offset + token.length
        end
        out << text.byteslice(pos..-1)
        out.force_encoding(text.encoding)
      rescue Puppet::ParseError
        text
      end
    end
  end
end
