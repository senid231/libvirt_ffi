# frozen_string_literal: true

module Libvirt
  module Util
    UNIT_TO_BYTES = {
        b: 1,
        bytes: 1,
        KB: 1_000,
        KiB: 1_024,
        k: 1_024,
        MB: 1_000_000,
        M: 1_048_576,
        MiB: 1_048_576,
        GB: 1_000_000_000,
        G: 1_073_741_824,
        GiB: 1_073_741_824,
        TB: 1_000_000_000_000,
        T: 1_099_511_627_776,
        TiB: 1_099_511_627_776
    }.freeze

    class << self
      attr_writer :logger

      attr_reader :logger

      def log(severity, prog = nil, &block)
        return if @logger.nil?

        @logger.public_send(severity, prog, &block)
      end

      def library_path
        %w[libvirt libvirt.so.0]
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
      # @param flags [Integer,Symbol,Array<Symbol>,Hash{Symbol=>Boolean},nil]
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
        flags = enum[flags] if flags.is_a?(Symbol)
        return flags if flags.is_a?(Integer)

        result = 0x0
        flags = flags.select { |_, v| v }.keys if flags.is_a?(Hash)

        raise ArgumentError, 'flags must be an Integer or a Hash or an Array' unless flags.is_a?(Array)

        flags.each do |key|
          result |= enum[key.to_s.upcase.to_sym]
        end

        result
      end

      # @param value [Integer,String]
      # @param unit [String,Symbol] default 'bytes'
      # @return [Integer] memory in bytes
      def parse_memory(value, unit)
        unit ||= 'bytes'
        multiplier = UNIT_TO_BYTES.fetch(unit.to_sym)
        Integer(value) * multiplier
      end
    end
  end
end
