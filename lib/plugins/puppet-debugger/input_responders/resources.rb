# frozen_string_literal: true

require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Resources < InputResponderPlugin
      COMMAND_WORDS = %w[resources].freeze
      SUMMARY = 'List all the resources current in the catalog.'
      COMMAND_GROUP = :scope

      def run(args = [])
        filter = args
        resources = find_resources(debugger.catalog.resources, filter)
        # resource references, which the formatter prints as File['/tmp/x']
        modified = resources.map { |res| Puppet::Pops::Types::TypeFactory.resource(res.type, res.title) }
        output = "Resources not shown in any specific order\n".warning
        output + format_value(modified)
      end

      def find_resources(resources, filter = [])
        return resources if filter.nil? || filter.empty?

        filter_string = filter.join(' ').downcase
        resources.find_all do |resource|
          resource.name.to_s.downcase.include?(filter_string) || resource.type.to_s.downcase.include?(filter_string)
        end
      end
    end
  end
end
