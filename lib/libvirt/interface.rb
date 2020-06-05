# frozen_string_literal: true

module Libvirt
  class Interface
    # @param pointer [FFI::Pointer]
    def self.load_ref(pointer)
      result = FFI::Interface.virInterfaceRef(pointer)
      raise Errors::LibError, "Couldn't retrieve interface reference" if result.negative?

      new(pointer)
    end

    # @param pointer [FFI::Pointer]
    def initialize(pointer)
      @ptr = pointer

      free = ->(obj_id) do
        dbg { "Finalize Libvirt::Interface object_id=0x#{obj_id.to_s(16)}, pointer=0x#{@ptr.address.to_s(16)}" }
        return unless @ptr

        warn "Couldn't free Libvirt::Interface object_id=0x#{obj_id.to_s(16)}, pointer=0x#{@ptr.address.to_s(16)}" if FFI::Interface.virInterfaceFree(@ptr).negative?
      end
      ObjectSpace.define_finalizer(self, free)
    end

    # @return [FFI::Pointer]
    def to_ptr
      @ptr
    end

    # @return [String]
    # @raise [Libvirt::Errors::LibError]
    def name
      result = FFI::Interface.virInterfaceGetName(@ptr)
      raise Errors::LibError, "Couldn't get interface name" if result.nil?

      result
    end

    # @return [String]
    # @raise [Libvirt::Errors::LibError]
    def mac
      result = FFI::Interface.virInterfaceGetMACString(@ptr)
      raise Errors::LibError, "Couldn't get interface mac" if result.nil?

      result
    end

    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @raise [Libvirt::Errors::LibError]
    def xml_desc(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Interface.enum_type(:xml_flags)
      result = FFI::Interface.virInterfaceGetXMLDesc(@ptr, flags)
      raise Errors::LibError, "Couldn't get interface xml desc" if result.nil?

      result
    end

    # @return [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def active?
      result = FFI::Interface.virInterfaceIsActive(@ptr)
      raise Errors::LibError, "Couldn't get interface is active" if result.nil?

      result == 1
    end

    # @raise [Libvirt::Errors::LibError]
    def start
      result = FFI::Interface.virInterfaceCreate(@ptr, 0)
      raise Errors::LibError, "Couldn't start interface" if result.negative?
    end

    # @raise [Libvirt::Errors::LibError]
    def destroy
      result = FFI::Interface.virInterfaceDestroy(@ptr, 0)
      raise Errors::LibError, "Couldn't destroy interface" if result.negative?
    end

    # @raise [Libvirt::Errors::LibError]
    def undefine
      result = FFI::Interface.virInterfaceUndefine(@ptr)
      raise Errors::LibError, "Couldn't undefine interface" if result.negative?
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Network', &block)
    end
  end
end
