# frozen_string_literal: true

require 'ffi'
require 'objspace'
require 'libvirt/util'
require 'libvirt/error'
require 'libvirt/ffi/common'
require 'libvirt/ffi/libvirt'
require 'libvirt/ffi/connection'
require 'libvirt/ffi/domain'
require 'libvirt/ffi/event'
require 'libvirt/ffi/node_info'
require 'libvirt/event'
require 'libvirt/connection'
require 'libvirt/domain'
require 'libvirt/node_info'
require 'libvirt/version'

module Libvirt
  EVENT_HANDLE_READABLE = 1
  EVENT_HANDLE_WRITABLE = 2
  EVENT_HANDLE_ERROR = 4
  EVENT_HANDLE_HANGUP = 8

  DOMAIN_EVENT_ID_LIFECYCLE = 0

  class << self
    def lib_version
      version_ptr = ::FFI::MemoryPointer.new(:ulong)
      code = FFI::Libvirt.virGetVersion(version_ptr, nil, nil)
      raise Error, 'failed to get version' if code < 0
      version_number = version_ptr.get_ulong(0)
      Libvirt::Util.parse_version(version_number)
    end

    def logger
      Util.logger
    end

    def logger=(logger)
      Util.logger = logger
    end
  end
end
