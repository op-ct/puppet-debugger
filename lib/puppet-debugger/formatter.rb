# frozen_string_literal: true

require 'puppet'
require 'puppet/pops'
require 'json'

module PuppetDebugger
  # Renders values the way the Puppet language writes them, using Puppet's own
  # StringConverter with the `%p` format: hashes one key per line, `undef` for
  # nil, single-quoted strings, types and resource references as written in
  # manifests. Objects StringConverter cannot render are first normalized to
  # plain data.
  module Formatter
    # the alternative flag gives hashes and arrays their multi-line layout; on a
    # scalar it means "quoted", so scalars use the plain form
    COLLECTION_FORMAT = '%#p'
    SCALAR_FORMAT = '%p'

    module_function

    # @param value [Object] a value the debugger evaluated or a command produced
    # @return [String] the rendered value. A RAL resource renders as its class
    #   name followed by its parameters, for example `Puppet::Type::File { ... }`.
    def format(value)
      return "#{value.class} #{convert(resource_hash(value))}" if ral_resource?(value)
      return format_resource_list(value) if value.is_a?(Array) && value.any? { |v| ral_resource?(v) }

      data = normalize(value)
      return '{}' if data == {}

      convert(data)
    end

    # @param value [Object] data StringConverter can render
    # @return [String]
    def convert(value)
      fmt = value.is_a?(Hash) || value.is_a?(Array) ? COLLECTION_FORMAT : SCALAR_FORMAT
      text = Puppet::Pops::Types::StringConverter.singleton.convert(value, fmt)
      text.gsub(/\{\n\s*\n\s*\}/, '{}') # an empty hash renders as "{", blank line, "}"
    rescue StandardError
      value.inspect
    end

    # @param values [Array] a list holding RAL resources, as the debugger returns for
    #   expressions that produce several resources
    # @return [String] one entry per line, each resource with its class name
    def format_resource_list(values)
      entries = values.map { |v| format(v).gsub(/^/, '  ') }
      "[\n#{entries.join(",\n")}\n]"
    end

    # Converts the objects the debugger meets into data StringConverter accepts:
    # facts objects to their hash, RAL and compiler resources to parameter hashes,
    # Bolt results and targets to the data they expose, and hashes to sorted,
    # string-keyed hashes.
    # @param value [Object]
    # @return [Object]
    def normalize(value)
      case value
      when Hash
        value.map { |k, v| [normalize_key(k), normalize(v)] }.sort_by { |k, _| k }.to_h
      when Array
        value.map { |v| normalize(v) }
      when Puppet::Node::Facts
        normalize(value.values)
      when Puppet::Parser::Resource
        normalize(value.to_ral)
      when Puppet::Type
        normalize(resource_hash(value))
      else
        normalize_object(value)
      end
    end

    # @param key [Object] a hash key
    # @return [String]
    def normalize_key(key)
      key.is_a?(String) ? key : key.to_s
    end

    # @param value [Object] anything that is not a core collection or a Puppet resource
    # @return [Object] the value, or the data it exposes through to_data / to_h
    def normalize_object(value)
      if defined?(::Bolt::Target) && value.is_a?(::Bolt::Target)
        normalize(value.to_h.merge(value.detail))
      elsif bolt_object?(value) && value.respond_to?(:to_data)
        normalize(value.to_data)
      else
        value
      end
    end

    # @param value [Object]
    # @return [Boolean] true for a RAL resource (an instance of a Puppet::Type subclass)
    def ral_resource?(value)
      value.is_a?(Puppet::Type)
    end

    # @param value [Object]
    # @return [Boolean] true for Bolt::Result, Bolt::ResultSet and friends
    def bolt_object?(value)
      value.class.name.to_s.start_with?('Bolt::')
    end

    # @param resource [Puppet::Type] a RAL resource
    # @return [Hash] its parameters plus name and title, with plain data values and
    #   string keys, sorted by key
    def resource_hash(resource)
      hash = resource.to_hash.merge(name: resource.name, title: resource.title)
      # a JSON round trip turns symbols, providers and other objects into plain data
      data = JSON.parse(hash.to_json)
      data.sort.to_h
    rescue StandardError
      hash.map { |k, v| [k.to_s, v.to_s] }.sort.to_h
    end
  end
end

require 'puppet-debugger/formatter/color'
