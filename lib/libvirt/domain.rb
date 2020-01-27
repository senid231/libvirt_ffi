# frozen_string_literal: true

require 'objspace'
require 'libvirt/ffi/domain'
require 'libvirt/util'

module Libvirt
  class Domain
    def initialize(dom_ptr, conn)
      @dom_ptr = dom_ptr
      @conn = conn
      ObjectSpace.define_finalizer(self, proc { |obj_id|
        STDOUT.puts("finalized Libvirt::Domain #{obj_id.to_s(16)}")
      })
    end

    def get_state
      state = ::FFI::MemoryPointer.new(:int)
      reason = ::FFI::MemoryPointer.new(:int)
      result = FFI::Domain.virDomainGetState(@dom_ptr, state, reason, 0)
      raise Error, "Couldn't get domain state" if result < 0
      [state.read_int, reason.read_int]
    end

    def to_ptr
      @dom_ptr
    end
  end
end
