# frozen_string_literal: true

module Libvirt
  class Network
    # @param pointer [FFI::Pointer]
    def self.load_ref(pointer)
      result = FFI::Network.virNetworkRef(pointer)
      raise Errors::LibError, "Couldn't retrieve network reference" if result.negative?

      new(pointer)
    end

    # @param pointer [FFI::Pointer]
    def initialize(pointer)
      @ptr = pointer

      free = ->(obj_id) do
        dbg { "Finalize Libvirt::Network object_id=0x#{obj_id.to_s(16)}, pointer=0x#{@ptr.address.to_s(16)}" }
        return unless @ptr

        warn "Couldn't free Libvirt::Network object_id=0x#{obj_id.to_s(16)}, pointer=0x#{@ptr.address.to_s(16)}" if FFI::Network.virNetworkFree(@ptr).negative?
      end
      ObjectSpace.define_finalizer(self, free)
    end

    # @return [FFI::Pointer]
    def to_ptr
      @ptr
    end

    # @return [String]
    # @raise [Libvirt::Errors::LibError]
    def uuid
      buff = ::FFI::MemoryPointer.new(:char, Util::UUID_STRING_BUFLEN)
      result = FFI::Network.virNetworkGetUUIDString(@ptr, buff)
      raise Errors::LibError, "Couldn't get network uuid" if result.negative?

      buff.read_string
    end

    # @return [String]
    # @raise [Libvirt::Errors::LibError]
    def name
      result = FFI::Network.virNetworkGetName(@ptr)
      raise Errors::LibError, "Couldn't get network name" if result.nil?

      result
    end

    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @raise [Libvirt::Errors::LibError]
    def xml_desc(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Network.enum_type(:xml_flags)
      result = FFI::Network.virNetworkGetXMLDesc(@ptr, flags)
      raise Errors::LibError, "Couldn't get network xml_desc" if result.nil?

      result
    end

    # @return [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def active?
      result = FFI::Network.virNetworkIsActive(@ptr)
      raise Errors::LibError, "Couldn't get network is active" if result.nil?

      result == 1
    end

    # @return [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def persistent?
      result = FFI::Network.virNetworkIsPersistent(@ptr)
      raise Errors::LibError, "Couldn't get network is persistent" if result.nil?

      result == 1
    end

    # @return [String]
    # @raise [Libvirt::Errors::LibError]
    def bridge_name
      result = FFI::Network.virNetworkGetBridgeName(@ptr)
      raise Errors::LibError, "Couldn't get network bridge_name" if result.nil?

      result
    end

    # @return [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def auto_start?
      value = ::FFI::MemoryPointer.new(:int)
      result = FFI::Network.virNetworkGetAutostart(@ptr, value)
      raise Errors::LibError, "Couldn't get network auto_start" if result.negative?

      value.read_int == 1
    end

    # @param value [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def set_auto_start(value)
      value = value ? 1 : 0
      result = FFI::Network.virNetworkSetAutostart(@ptr, value)
      raise Errors::LibError, "Couldn't set network auto_start" if result.negative?
    end

    # @param mac [String]
    # @return [Integer]
    # @raise [Libvirt::Errors::LibError]
    def dhcp_leases_qty(mac = nil)
      result = FFI::Network.virNetworkGetDHCPLeases(@ptr, mac, nil, 0)
      raise Errors::LibError, "Couldn't get network dhcp leases qty" if result.nil?

      result
    end

    # @param mac [String]
    # @return [Array<Libvirt::NetworkDhcpLease>, Array]
    # @raise [Libvirt::Errors::LibError]
    def dhcp_leases(mac = nil)
      size = dhcp_leases_qty(mac)
      return [] if size.zero?

      dhcp_leases_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Network.virNetworkGetDHCPLeases(@ptr, mac, dhcp_leases_ptr, 0)
      raise Errors::LibError, "Couldn't retrieve network dhcp leases" if result.negative?

      ptr = dhcp_leases_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |dhcpl_ptr| NetworkDhcpLease.new(dhcpl_ptr) }
    end

    # @raise [Libvirt::Errors::LibError]
    def start
      result = FFI::Network.virNetworkCreate(@ptr)
      raise Errors::LibError, "Couldn't start network" if result.negative?
    end

    # @raise [Libvirt::Errors::LibError]
    def destroy
      result = FFI::Network.virNetworkDestroy(@ptr)
      raise Errors::LibError, "Couldn't destroy network" if result.negative?
    end

    # @raise [Libvirt::Errors::LibError]
    def undefine
      result = FFI::Network.virNetworkUndefine(@ptr)
      raise Errors::LibError, "Couldn't undefine network" if result.negative?
    end

    # @param xml [String]
    # @param command [Integer, Symbol]
    # @param section [Integer, Symbol]
    # @param flags [Integer, Symbol]
    # @param parent_index [Integer] default -1 (means don't care)
    # @raise [Libvirt::Errors::LibError]
    def update(xml, command, section, flags, parent_index = -1)
      command = Util.parse_flags command, FFI::Network.enum_type(:update_command)
      section = Util.parse_flags section, FFI::Network.enum_type(:update_section)
      flags = Util.parse_flags flags, FFI::Network.enum_type(:update_flags)

      result = FFI::Network.virNetworkUpdate(
          @ptr,
          command,
          section,
          parent_index,
          xml,
          flags
      )
      raise Errors::LibError, "Couldn't update network" if result.negative?
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Network', &block)
    end
  end
end
