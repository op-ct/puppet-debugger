# frozen_string_literal: true

module PuppetDebugger
  module Support
    module Facts
      # in the future we will want to grab real facts from real systems via puppetdb
      # or enc data

      # allow the user to specify the facterdb filter
      def dynamic_facterdb_filter
        ENV['DEBUGGER_FACTERDB_FILTER'] || default_facterdb_filter
      end

      def default_facterdb_filter
        "os.name=#{facter_os_name} and os.release.major=#{facter_os_version} and os.architecture=x86_64 and facterversion=#{facter_version}"
      end

      def facter_version
        ENV['DEBUGGER_FACTER_VERSION'] || default_facter_version
      end

      # return the correct supported version of facter facts
      def default_facter_version
        '/^4/'
      end

      def facter_os_name
        ENV['DEBUGGER_FACTER_OS_NAME'] || 'Rocky'
      end

      def facter_os_version
        ENV['DEBUGGER_FACTER_OS_VERSION'] || '8'
      end

      def set_facts(value)
        @facts = value
      end

      # uses facterdb (cached facts) and retrives the facts given a filter
      # creates a new facts object
      # we could also use fact_merge to get real facts from the real system or puppetdb
      def node_facts
        node_facts = FacterDB.get_facts(dynamic_facterdb_filter).first
        if node_facts.nil?
          message = <<~OUT
            Using filter: #{dynamic_facterdb_filter}
            Bad FacterDB filter, please change the filter so it returns a result set.
            Use puppet debugger --no-facterdb to disable facterdb.
            See https://github.com/voxpupuli/facterdb/#with-a-string-filter
          OUT
          raise PuppetDebugger::Exception::BadFilter, message: message
        end
        # fix for when --show-legacy facts are not part of the facter 3 fact set
        node_facts[:fqdn] = node_facts[:networking].fetch('fqdn', nil) unless node_facts[:fqdn]
        node_facts
      end

      def default_facts
        unless @facts
          values = Hash[node_facts.map { |k, v| [k.to_s, v] }]
          name = values['fqdn']
          @facts ||= Puppet::Node::Facts.new(name, values)
        end
        @facts
      end

      def server_facts
        data = {}
        data['servername'] = Facter.value('fqdn') || Facter.value('networking')['fqdn']
        data['serverip'] = Facter.value('ipaddress')
        data['serverversion'] = Puppet.version.to_s
        data
      end
    end
  end
end
