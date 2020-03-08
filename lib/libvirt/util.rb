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

      # Bitwise OR integer flags calculation for C language.
      # @param flags [Integer,Array<Symbol>,Hash{Symbol=>Boolean},nil]
      # @param enum [FFI::Enum]
      # @param default [Integer] optional (default 0x0)
      # @return [Integer] bitwise OR of keys
      #  @example Usage:
      #    parse_flags(nil, enum)
      #    parse_flags({MANAGED_SAVE: true, SNAPSHOTS_METADATA: true, NVRAM: false}, enum)
      #    parse_flags({managed_save: true, snapshots_metadata: true, keep_nvram: nil}, enum)
      #    parse_flags(3, enum)
      #    parse_flags([:MANAGED_SAVE, :SNAPSHOTS_METADATA], enum)
      #    parse_flags([:managed_save, :snapshots_metadata], enum)
      #
      def parse_flags(flags, enum, default: 0x0)
        flags = default if flags.nil?
        return flags if flags.is_a?(Integer)

        result = 0x0
        flags = flags.select { |_, v| v }.keys if flags.is_a?(Hash)

        if flags.is_a?(Array)
          flags.each do |key|
            result |= enum[key.to_s.upcase.to_sym]
          end
        else
          raise ArgumentError, "flags must be an Integer or a Hash or an Array"
        end

        result
      end

    end
  end
end
