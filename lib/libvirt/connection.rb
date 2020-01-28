# frozen_string_literal: true

module Libvirt
  class Connection
    def initialize(uri)
      @uri = uri
      @conn_ptr = ::FFI::Pointer.new(0)
      @cb_data = {}
      ObjectSpace.define_finalizer(self, proc { |obj_id|
        STDOUT.puts("finalized Libvirt::Connection #{obj_id.to_s(16)}")
      })
    end

    def open
      @conn_ptr = FFI::Connection.virConnectOpen(@uri)
      raise Error, "Couldn't connect to #{@uri.inspect}" if @conn_ptr.null?
      true
    end

    def opened?
      !@conn_ptr.null?
    end

    def to_ptr
      @conn_ptr
    end

    def version
      check_open!

      version_ptr = ::FFI::MemoryPointer.new(:ulong)
      result = FFI::Connection.virConnectGetVersion(@conn_ptr, version_ptr)
      raise Error, "Couldn't retrieve connection version" if result < 0
      version_number = version_ptr.get_ulong(0)
      Libvirt::Util::parse_version(version_number)
    end

    def set_keep_alive(interval, count)
      result = FFI::Connection.virConnectSetKeepAlive(@conn_ptr, interval, count)
      raise Error, "Couldn't set connection keep_alive" if result < 0
      result == 0
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} @uri=#{@uri.inspect} @conn_ptr=0x#{@conn_ptr.address.to_s(16)}>"
    end

    def inspect
      to_s
    end

    def list_all_domains_qty(flags = 0)
      result = FFI::Domain.virConnectListAllDomains(@conn_ptr, nil, flags)
      raise Error, "Couldn't retrieve domains qty with flags #{flags.to_s(16)}" if result < 0
      result
    end

    def list_all_domains(flags = 0)
      size = list_all_domains_qty(flags)
      domains_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Domain.virConnectListAllDomains(@conn_ptr, domains_ptr, flags)
      raise Error, "Couldn't retrieve domains list with flags #{flags.to_s(16)}" if result < 0
      ptr = domains_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |dom_ptr| Libvirt::Domain.new(dom_ptr, self) }
    end

    # @yield conn, dom
    def register_domain_event_callback(event_id, domain = nil, opaque = nil, &block)
      if event_id == Libvirt::DOMAIN_EVENT_ID_LIFECYCLE
        cb = FFI::Domain::domain_event_id_lifecycle_callback(&block)
      else
        raise Error, "not supported event_id #{event_id.inspect}"
      end

      result = FFI::Domain.virConnectDomainEventRegisterAny(
          @conn_ptr,
          domain&.to_ptr,
          event_id,
          cb,
          opaque&.to_ptr,
          nil # free_opaque
      )
      raise Error, "Couldn't register domain event callback" if result < 0

      @cb_data[result] = { event_id: event_id, cb: cb, opaque: opaque }
      result
    end

    def deregister_domain_event_callback(callback_id)
      @cb_data.delete(callback_id)
      result = FFI::Domain.virConnectDomainEventDeregisterAny(@conn_ptr, callback_id)
      raise Error, "Couldn't deregister domain event callback" if result < 0
      true
    end

    private

    def check_open!
      raise Error, "Connection to #{@uri.inspect} is not open" if @conn_ptr.null?
    end
  end
end
