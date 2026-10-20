# frozen_string_literal: true

require 'json'
require 'puppet/util/yaml'

module PuppetDebugger
  module Support
    # Supplies the facts for the node being debugged when no scope was handed in.
    # They come, in order of preference, from a facts file (`--facts`), from the
    # facterdb gem when it is asked for, or from this machine through Puppet's
    # facts indirection. facterdb is optional: it is only required when used.
    module Facts
      class << self
        # this machine's facts, gathered once per process
        attr_accessor :local_facts_cache
      end

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

      # @return [String, nil] the facts file given with --facts
      def facts_file
        options[:facts] if respond_to?(:options) && options
      end

      # @return [Boolean] true when facts should come from facterdb: the use_facterdb
      #   option says so, or a filter was given in DEBUGGER_FACTERDB_FILTER
      def use_facterdb?
        if respond_to?(:options) && options && !options[:use_facterdb].nil?
          options[:use_facterdb]
        else
          !ENV['DEBUGGER_FACTERDB_FILTER'].nil?
        end
      end

      # @return [Boolean] true when the facterdb gem could be loaded
      def load_facterdb
        require 'facterdb'
        true
      rescue LoadError
        false
      end

      # @return [String] the command that installs facterdb for the running Ruby
      def facterdb_install_command
        "#{RbConfig.ruby} -S gem install --user-install facterdb"
      end

      # @return [Hash] the facts for the node, with symbol keys at the top level
      def node_facts
        values = if facts_file
                   facts_from_file(facts_file)
                 elsif use_facterdb?
                   facterdb_facts
                 else
                   local_facts
                 end
        values = values.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
        # fix for when --show-legacy facts are not part of the facter 3 fact set
        values[:fqdn] ||= values[:networking]['fqdn'] if values[:networking].is_a?(Hash)
        values
      end

      # uses facterdb (cached facts) and retrieves the facts given a filter
      # @return [Hash]
      def facterdb_facts
        raise PuppetDebugger::Exception::FacterDBNotInstalled, install: facterdb_install_command unless load_facterdb

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
        node_facts
      end

      # @param path [String] a JSON or YAML file holding either a plain facts hash
      #   (`facter --json`, a facterdb fixture) or Puppet's facts document with
      #   "name" and "values" keys (`puppet facts`, a cached facts file)
      # @return [Hash]
      def facts_from_file(path)
        content = File.read(path)
        data = if path =~ /\.ya?ml\z/i
                 Puppet::Util::Yaml.safe_load(content, [Symbol, Time, Puppet::Node::Facts], path)
               else
                 JSON.parse(content)
               end
        data = data.values if data.is_a?(Puppet::Node::Facts)
        data = data['values'] if data.is_a?(Hash) && data.key?('values') && data.key?('name')
        raise PuppetDebugger::Exception::BadFactsFile, path: path unless data.is_a?(Hash)

        data
      rescue JSON::ParserError, Puppet::Util::Yaml::YamlLoadError, Errno::ENOENT => e
        raise PuppetDebugger::Exception::BadFactsFile, path: path, message: e.message
      end

      # @return [Hash] this machine's facts, from Puppet's facts indirection
      def local_facts
        Facts.local_facts_cache ||= begin
          facts = Puppet::Node::Facts.indirection.find(Puppet[:node_name_value])
          raise PuppetDebugger::Exception::FatalError, message: "Could not find facts for #{Puppet[:node_name_value]}" unless facts

          facts.values
        end
      end

      def default_facts
        unless @facts
          values = node_facts.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
          name = values['fqdn'] || Puppet[:node_name_value]
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
