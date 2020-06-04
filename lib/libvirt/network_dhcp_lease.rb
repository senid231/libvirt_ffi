# frozen_string_literal: true

module Libvirt
  class NetworkDhcpLease < BaseInfo
    struct_class FFI::Network::DhcpLeaseStruct

    # @param pointer [FFI::Pointer]
    def initialize(pointer)
      super

      free = ->(obj_id) do
        dbg { "Finalize Libvirt::NetworkDhcpLease object_id=0x#{obj_id.to_s(16)}, pointer=0x#{@ptr.address.to_s(16)}" }
        return unless @ptr

        warn "Couldn't free Libvirt::NetworkDhcpLease object_id=0x#{obj_id.to_s(16)}, pointer=0x#{@ptr.address.to_s(16)}" if FFI::Storage.virNetworkDHCPLeaseFree(@ptr).negative?
      end
      ObjectSpace.define_finalizer(self, free)
    end
  end
end
