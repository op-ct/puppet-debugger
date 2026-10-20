# frozen_string_literal: true

require 'singleton'
require 'puppet-debugger/support/errors'
require 'forwardable'

module PuppetDebugger
  class InputResponderPlugin
    include Singleton
    extend Forwardable

    # Plugin files live at this path under a lib directory, in this gem, in a plugin gem,
    # or on RUBYLIB. Gem.find_files searches installed gems and $LOAD_PATH for the glob.
    PLUGIN_GLOB = 'plugins/puppet-debugger/input_responders/*.rb'

    # @return [Array<Class>] every subclass defined so far, in definition order
    def self.registry
      InputResponderPlugin.instance_variable_get(:@registry) ||
        InputResponderPlugin.instance_variable_set(:@registry, [])
    end

    def self.inherited(subclass)
      super
      registry << subclass unless registry.include?(subclass)
    end

    # Requires every plugin file RubyGems or the load path can see, once, and
    # returns the plugin classes sorted by name.
    # @return [Array<Class>]
    def self.load_plugins
      unless InputResponderPlugin.instance_variable_get(:@plugins_loaded)
        Gem.find_files(PLUGIN_GLOB).map { |f| File.expand_path(f) }.uniq.each { |file| require file }
        InputResponderPlugin.instance_variable_set(:@plugins_loaded, true)
      end
      registry.sort_by(&:name)
    end
    attr_accessor :debugger
    def_delegators :debugger, :scope, :node, :environment, :loaders, :puppet_environment,
                   :add_hook, :handle_input, :delete_hook, :puppet_lib_dir, :format_value
    def_delegators :scope, :compiler, :catalog
    def_delegators :node, :facts

    # @return [Array[String]] an array of words the user can call the command with
    def self.command_words
      self::COMMAND_WORDS
    end

    def modules_paths
      debugger.puppet_environment.full_modulepath
    end

    # @return [String] a summary of the plugin
    def self.summary
      self::SUMMARY
    end

    # @return [String] the name of the command group the plugin is in
    def self.command_group
      self::COMMAND_GROUP
    end

    # @return [Hash] a has of all the details of the plugin
    def self.details
      { words: command_words, summary: summary, group: command_group }
    end

    # @param buffer_words [Array[String]] a array of words the user has typed in
    # @return Array[String] - an array of words that will help the user with word completion
    # By default this returns an empty array, your plugin can chose to override this method in order to
    # provide the user with a list of key words based on the user's input
    def self.command_completion(_buffer_words)
      []
    end

    # @param args [Array[String]] - an array of arguments to pass to the plugin command
    # @param debugger PuppetDebugger::Cli  - an instance of the PuppetDebugger::Cli object
    # @return the output of the plugin command
    def self.execute(args = [], debugger)
      instance.debugger = debugger
      instance.run(args)
    end

    # @param args [Array[String]] - an array of arguments to pass to the plugin command
    # @return the output of the plugin command
    def run(args = [])
      raise NotImplementedError
    end

    # this is the lib directory of this gem
    # in order to load any puppet functions from this gem we need to add the lib path
    # of this gem
    def puppet_debugger_lib_dir
      File.expand_path(File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'lib'))
    end
  end
end
