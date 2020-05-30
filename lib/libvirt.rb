# frozen_string_literal: true

require 'ffi'
require 'objspace'
require 'libvirt/host_callback_storage'
require 'libvirt/util'
require 'libvirt/errors'
require 'libvirt/ffi'
require 'libvirt/base_info'
require 'libvirt/node_info'
require 'libvirt/storage_pool_info'
require 'libvirt/storage_volume_info'
require 'libvirt/event'
require 'libvirt/connection'
require 'libvirt/domain'
require 'libvirt/stream'
require 'libvirt/storage_pool'
require 'libvirt/storage_volume'
require 'libvirt/version'

module Libvirt
  EVENT_HANDLE_READABLE = 1
  EVENT_HANDLE_WRITABLE = 2
  EVENT_HANDLE_ERROR = 4
  EVENT_HANDLE_HANGUP = 8

  class << self
    def lib_version
      version_ptr = ::FFI::MemoryPointer.new(:ulong)
      code = FFI::Host.virGetVersion(version_ptr, nil, nil)
      raise Errors::LibError, 'failed to get version' if code.negative?

      version_number = version_ptr.get_ulong(0)
      Util.parse_version(version_number)
    end

    def logger
      Util.logger
    end

    def logger=(logger)
      Util.logger = logger
    end
  end
end
