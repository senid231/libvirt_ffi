# frozen_string_literal: true

module Libvirt
  class Domain

    def self.load_ref(dom_ptr)
      ref_result = FFI::Domain.virDomainRef(dom_ptr)
      raise Error, "Couldn't retrieve domain reference" if ref_result < 0
      new(dom_ptr)
    end

    def initialize(dom_ptr)
      @dom_ptr = dom_ptr

      free = ->(obj_id) do
        return unless @dom_ptr
        fr_result = FFI::Domain.virDomainFree(@dom_ptr)
        STDERR.puts "Couldn't free Libvirt::Domain (0x#{obj_id.to_s(16)}) pointer #{@dom_ptr.address}" if fr_result < 0
      end
      ObjectSpace.define_finalizer(self, free)
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

    def uuid
      buff = ::FFI::MemoryPointer.new(:char, FFI::Domain::UUID_STRING_BUFLEN)
      result = FFI::Domain.virDomainGetUUIDString(@dom_ptr, buff)
      raise Error, "Couldn't get domain uuid" if result < 0
      buff.read_string
    end

    def name
      FFI::Domain.virDomainGetName(@dom_ptr)
    end

    def max_vcpus
      FFI::Domain.virDomainGetMaxVcpus(@dom_ptr)
    end

    # def vcpus
    #   # https://github.com/libvirt/ruby-libvirt/blob/9f71ff5add1f57ffef7cf513b72638d92d9fd84f/ext/libvirt/domain.c#L787
    #   # dominfo = virDomainGetInfo
    #   # dominfo.nrVirtCpu
    #   # maxcpus = ruby_libvirt_get_maxcpus(ruby_libvirt_connect_get(d));
    #   # vcpu_infos_ptr
    #   FFI::Domain.virDomainGetVcpus(@dom_ptr, vcpu_infos_ptr, maxinfo, cpumaps, maplen)
    # end
    def vcpus
      OpenStruct.new(count: max_vcpus)
    end

    def max_memory
      FFI::Domain.virDomainGetMaxMemory(@dom_ptr)
    end

    def xml_desc(flags = 0)
      FFI::Domain.virDomainGetXMLDesc(@dom_ptr, flags)
    end

    def screenshot(stream, display = 0)
      mime_type, pointer = FFI::Domain.virDomainScreenshot(@dom_ptr, stream.to_ptr, display, 0)
      raise Error, "Couldn't attach domain screenshot" if pointer.null?
      # free pointer required
      mime_type
    end

    def free_domain
      result = FFI::Domain.virDomainFree(@dom_ptr)
      raise Error, "Couldn't free domain" if result < 0
      @dom_ptr = nil
    end
  end
end
