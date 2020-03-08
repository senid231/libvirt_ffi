# frozen_string_literal: true

module Libvirt
  module FFI
    # namespace for libvirt C bindings
    require 'libvirt/ffi/helpers'
    require 'libvirt/ffi/common'
    require 'libvirt/ffi/host'
    require 'libvirt/ffi/domain'
    require 'libvirt/ffi/event'
    require 'libvirt/ffi/stream'
  end
end
