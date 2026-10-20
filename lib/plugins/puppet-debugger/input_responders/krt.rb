# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Krt < InputResponderPlugin
      COMMAND_WORDS = %w[krt].freeze
      SUMMARY = 'List all the known resource types.'
      COMMAND_GROUP = :scope

      def run(_args = [])
        format_value(debugger.known_resource_types)
      end
    end
  end
end
