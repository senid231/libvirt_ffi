# frozen_string_literal: true

module Libvirt
  class Domain
    def self.load_ref(dom_ptr)
      ref_result = FFI::Domain.virDomainRef(dom_ptr)
      raise Errors::LibError, "Couldn't retrieve domain reference" if ref_result.negative?

      new(dom_ptr)
    end

    def initialize(dom_ptr)
      @dom_ptr = dom_ptr

      free = ->(obj_id) do
        Util.log(:debug) { "Finalize Libvirt::Domain 0x#{obj_id.to_s(16)} @dom_ptr=#{@dom_ptr}," }
        return unless @dom_ptr

        fr_result = FFI::Domain.virDomainFree(@dom_ptr)
        warn "Couldn't free Libvirt::Domain (0x#{obj_id.to_s(16)}) pointer #{@dom_ptr.address}" if fr_result.negative?
      end
      ObjectSpace.define_finalizer(self, free)
    end

    def get_state
      state = ::FFI::MemoryPointer.new(:int)
      reason = ::FFI::MemoryPointer.new(:int)
      result = FFI::Domain.virDomainGetState(@dom_ptr, state, reason, 0)
      raise Errors::LibError, "Couldn't get domain state" if result.negative?

      state_sym = FFI::Domain.enum_type(:state)[state.read_int]
      reason_sym = FFI::Domain.state_reason(state_sym, reason.read_int)
      [state_sym, reason_sym]
    end

    def to_ptr
      @dom_ptr
    end

    def uuid
      buff = ::FFI::MemoryPointer.new(:char, Util::UUID_STRING_BUFLEN)
      result = FFI::Domain.virDomainGetUUIDString(@dom_ptr, buff)
      raise Errors::LibError, "Couldn't get domain uuid" if result.negative?

      buff.read_string
    end

    def name
      result = FFI::Domain.virDomainGetName(@dom_ptr)
      raise Errors::LibError, "Couldn't retrieve storage pool name" if result.nil?

      result
    end

    def max_vcpus
      FFI::Domain.virDomainGetMaxVcpus(@dom_ptr)
    end

    # @return [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def auto_start
      value = ::FFI::MemoryPointer.new(:int)
      result = FFI::Domain.virDomainGetAutostart(@dom_ptr, value)
      raise Errors::LibError, "Couldn't get domain uuid" if result.negative?

      value.read_int == 1
    end

    # @param value [Boolean]
    # @raise [Libvirt::Errors::LibError]
    def set_auto_start(value)
      value = value ? 1 : 0
      result = FFI::Domain.virDomainSetAutostart(@dom_ptr, value)
      raise Errors::LibError, "Couldn't get domain uuid" if result.negative?
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
      dbg { "#screenshot stream=#{stream}, display=#{display}," }

      mime_type, pointer = FFI::Domain.virDomainScreenshot(@dom_ptr, stream.to_ptr, display, 0)
      raise Errors::LibError, "Couldn't attach domain screenshot" if pointer.null?

      # free pointer required
      mime_type
    end

    def free_domain
      result = FFI::Domain.virDomainFree(@dom_ptr)
      raise Errors::LibError, "Couldn't free domain" if result.negative?

      @dom_ptr = nil
    end

    def start(flags = 0)
      result = FFI::Domain.virDomainCreateWithFlags(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't start domain" if result.negative?
    end

    def reboot(flags = 0)
      result = FFI::Domain.virDomainReboot(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't reboot domain" if result.negative?
    end

    def shutdown(flags = :ACPI_POWER_BTN)
      result = FFI::Domain.virDomainShutdownFlags(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't shutdown domain" if result.negative?
    end

    def power_off(flags = 0)
      result = FFI::Domain.virDomainDestroyFlags(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't power off domain" if result.negative?
    end

    def reset(flags = 0)
      result = FFI::Domain.virDomainReset(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't reset domain" if result.negative?
    end

    def suspend
      result = FFI::Domain.virDomainSuspend(@dom_ptr)
      raise Errors::LibError, "Couldn't suspend domain" if result.negative?
    end

    def resume
      result = FFI::Domain.virDomainResume(@dom_ptr)
      raise Errors::LibError, "Couldn't resume domain" if result.negative?
    end

    # Undefine a domain.
    # If the domain is running, it's converted to transient domain, without stopping it.
    # If the domain is inactive, the domain configuration is removed.
    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @see Libvirt::FFI::Domain enum :undefine_flags_values for acceptable keys
    # @see Libvirt::Util.parse_flags for possible argument values
    # @raise [Libvirt::Errors::LibError] if operation failed
    def undefine(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Domain.enum_type(:undefine_flags_values)
      result = FFI::Domain.virDomainUndefineFlags(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't resume domain" if result.negative?
    end

    # After save_memory(:PAUSED) you need to call #start and #resume
    # to move domain to the running state.
    def save_memory(flags = :PAUSED)
      result = FFI::Domain.virDomainManagedSave(@dom_ptr, flags)
      raise Errors::LibError, "Couldn't save domain memory" if result.negative?
    end

    # Sets metadata
    # @param metadata [String] xml node for element type, text for other types
    #   DESCRIPTION 0x0 - Operate on <description>
    #   TITLE 0x1 - Operate on <title>
    #   ELEMENT 0x2 - Operate on <metadata>
    # @param type [Integer,Symbol] one of :ELEMENT, :TITLE, :DESCRIPTION
    # @param key [String] xml key (required for type element)
    # @param uri [String] xml namespace (required for type element)
    # @param flags [Integer,Symbol] one off AFFECT_CURRENT, AFFECT_CONFIG, AFFECT_LIVE
    #   AFFECT_CURRENT 0x0 - Affect current domain state.
    #   AFFECT_LIVE 0x1 - Affect running domain state.
    #   AFFECT_CONFIG 0x2 - Affect persistent domain state.
    # @raise [Libvirt::Errors::LibError] if operation failed
    def set_metadata(metadata, type: :ELEMENT, key: nil, uri: nil, flags: :AFFECT_CURRENT)
      result = FFI::Domain.virDomainSetMetadata(@dom_ptr, type, metadata, key, uri, flags)
      raise Errors::LibError, "Couldn't set domain metadata" if result.negative?
    end

    # Retrieves metadata
    # @param type [Integer,Symbol] one of :ELEMENT, :TITLE, :DESCRIPTION
    # @param uri [String] xml namespace (required for type element)
    # @param flags [Integer,Symbol] one off AFFECT_CURRENT, AFFECT_CONFIG, AFFECT_LIVE
    #   AFFECT_CURRENT 0x0 - Affect current domain state.
    #   AFFECT_LIVE 0x1 - Affect running domain state.
    #   AFFECT_CONFIG 0x2 - Affect persistent domain state.
    # @raise [Libvirt::Errors::LibError] if operation failed
    # @return [String] xml node, title, or description.
    def get_metadata(type: :ELEMENT, uri: nil, flags: :AFFECT_CURRENT)
      result = FFI::Domain.virDomainGetMetadata(@dom_ptr, type, uri, flags)
      raise Errors::LibError, "Couldn't get domain metadata" if result.nil?

      result
    end

    def persistent?
      result = FFI::Domain.virDomainIsPersistent(@dom_ptr)
      raise Errors::LibError, "Couldn't set domain metadata" if result.negative?

      result == 1
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Domain', &block)
    end
  end
end
