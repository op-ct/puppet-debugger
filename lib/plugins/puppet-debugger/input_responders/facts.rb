# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Facts < InputResponderPlugin
      COMMAND_WORDS = %w[facts].freeze
      SUMMARY = 'List all the facts associated with the node.'
      COMMAND_GROUP = :node

      def run(_args = [])
        variables = debugger.node.facts.values
        format_value(variables)
      end
    end
  end
end
