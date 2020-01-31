# frozen_string_literal: true

module Libvirt
  module Util
    class << self

      def logger=(logger)
        @logger = logger
      end

      def logger
        @logger
      end

      def log(severity, prog = nil, &block)
        return if @logger.nil?
        @logger.public_send(severity, prog, &block)
      end

      def library_path
        %w(libvirt libvirt.so.0)
      end

      # @param [Integer] version_number ulong
      def parse_version(version_number)
        major = version_number / 1_000_000
        minor = (version_number - major * 1_000_000) / 1_000
        release = version_number - major * 1_000_000 - minor * 1_000
        "#{major}.#{minor}.#{release}"
      end

      # @param enum [FFI::Enum]
      # @param value [Symbol, Integer]
      # @return [Array] event_id, event_id_sym
      # @raise ArgumentError
      def parse_enum(enum, value)
        if value.is_a?(Symbol)
          raise ArgumentError, 'invalid enum value' unless enum.symbols.include?(value)
          return [enum.find(value), value]
        end

        raise ArgumentError, 'invalid enum value' unless enum.symbol_map.values.include?(value)
        [value, enum.symbol_map[value]]
      end

    end
  end
end
