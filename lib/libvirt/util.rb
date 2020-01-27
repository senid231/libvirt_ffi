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
        'libvirt'
      end

      # @param [Integer] version_number ulong
      def parse_version(version_number)
        major = version_number / 1_000_000
        minor = (version_number - major * 1_000_000) / 1_000
        release = version_number - major * 1_000_000 - minor * 1_000
        "#{major}.#{minor}.#{release}"
      end

    end
  end
end
