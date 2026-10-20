# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class FacterdbFilter < InputResponderPlugin
      COMMAND_WORDS = %w[facterdb_filter ff].freeze
      SUMMARY = 'Set the facterdb filter'
      COMMAND_GROUP = :node

      # displays the facterdb filter
      # @param [Array] - args is not used
      def run(_args = [])
        out = format_value(debugger.dynamic_facterdb_filter)
        return out if debugger.load_facterdb

        "#{out}\n#{'facterdb gem is not installed; facts come from this machine or --facts FILE'.warning}"
      end
    end
  end
end
