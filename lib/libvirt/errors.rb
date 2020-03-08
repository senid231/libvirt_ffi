# frozen_string_literal: true

module Libvirt
  module Errors
    class Error < StandardError
      # Generic error
    end

    class LibError < Error
      # Object contains detailed error information retrieved from libvirt.

      ERROR_FIELDS = [:code, :domain, :message, :level].freeze

      attr_reader :client_message,
                  :error_data,
                  :error_code,
                  :error_domain,
                  :error_message,
                  :error_level

      # @param client_message [String, nil] optional client message
      # When client_message ommited and virGetLastError return error
      # message will be following: "ERROR_LEVEL: ERROR_NUMBER (ERROR_DOMAIN) ERROR_MESSAGE".
      # When client message provided and virGetLastError return error
      # message will be following: "CLIENT_MESSAGE\nERROR_LEVEL: ERROR_NUMBER (ERROR_DOMAIN) ERROR_MESSAGE".
      # When client message is provided and virGetLastError return no error
      # message will be following: "CLIENT_MESSAGE".
      def initialize(client_message = nil)
        @client_message = client_message
        ptr = FFI::Error.virGetLastError
        unless ptr.null?
          struct = FFI::Error::Struct.new(ptr)
          @error_data = struct.members.map { |m| [m, struct[m]] }.to_h
          @error_code = error_data[:code]
          @error_domain = error_data[:domain]
          @error_message = error_data[:message]
          @error_level = error_data[:level]
        end

        super(build_message)
      end

      private

      def build_message
        if error_data.nil?
          client_message
        elsif client_message.nil?
          '%s: %s (%s) %s' % [error_level, error_code, error_domain, error_message]
        else
          "%s\n%s: %s (%s) %s" % [client_message, error_level, error_code, error_domain, error_message]
        end
      end
    end
  end
end
