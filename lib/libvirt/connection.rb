# frozen_string_literal: true

module Libvirt
  class Connection
    DOMAIN_EVENT_IDS = FFI::Domain.enum_type(:event_id).symbols.dup.freeze

    STORAGE = DomainCallbackStorage.new

    DOMAIN_EVENT_CALLBACKS = FFI::Domain.enum_type(:event_id).symbol_map.map do |name, event_id|
      func = FFI::Domain.event_callback(event_id) do |conn_ptr, dom_ptr, *args, op_ptr|
        connection = Connection.load_ref(conn_ptr)
        domain = Domain.load_ref(dom_ptr)
        block, opaque = STORAGE.retrieve_from_pointer(op_ptr)
        block.call(connection, domain, *args, opaque)
      end
      [name, func]
    end.to_h

    def self.load_ref(conn_ptr)
      ref_result = FFI::Connection.virConnectRef(conn_ptr)
      raise Error, "Couldn't retrieve connection reference" if ref_result < 0
      new(nil).send(:set_connection, conn_ptr)
    end

    def initialize(uri)
      @uri = uri
      @conn_ptr = ::FFI::Pointer.new(0)

      free = ->(obj_id) do
        return if @conn_ptr.null?
        cl_result = FFI::Connection.virConnectClose(@conn_ptr)
        STDERR.puts "Couldn't close Libvirt::Connection (0x#{obj_id.to_s(16)}) pointer #{@conn_ptr.address}" if cl_result < 0
      end
      ObjectSpace.define_finalizer(self, free)
    end

    def open
      @conn_ptr = FFI::Connection.virConnectOpen(@uri)
      raise Error, "Couldn't open connection to #{@uri.inspect}" if @conn_ptr.null?
      true
    end

    def close
      result = FFI::Connection.virConnectClose(@conn_ptr)
      raise Error, "Couldn't close connection to #{@uri.inspect}" if result < 0
      @conn_ptr = ::FFI::Pointer.new(0)
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
      ptr.get_array_of_pointer(0, size).map { |dom_ptr| Libvirt::Domain.new(dom_ptr) }
    end

    # @yield conn, dom, *args
    def register_domain_event_callback(event_id, domain = nil, opaque = nil, &block)
      dbg { "#register_domain_event_callback event_id=#{event_id}" }

      enum = FFI::Domain.enum_type(:event_id)
      event_id, event_id_sym = Util.parse_enum(enum, event_id)
      cb = DOMAIN_EVENT_CALLBACKS.fetch(event_id_sym)

      cb_data, cb_data_free_func = STORAGE.allocate_struct

      result = FFI::Domain.virConnectDomainEventRegisterAny(
          @conn_ptr,
          domain&.to_ptr,
          event_id,
          cb,
          cb_data.pointer,
          cb_data_free_func
      )
      if result < 0
        cb_data.pointer.free
        raise Error, "Couldn't register domain event callback"
      end

      STORAGE.store_struct(
          cb_data,
          connection_pointer: @conn_ptr,
          callback_id: result,
          cb: block,
          opaque: opaque
      )
      result
    end

    def deregister_domain_event_callback(callback_id)
      dbg { "#deregister_domain_event_callback callback_id=#{callback_id}" }

      result = FFI::Domain.virConnectDomainEventDeregisterAny(@conn_ptr, callback_id)
      raise Error, "Couldn't deregister domain event callback" if result < 0

      # virConnectDomainEventDeregisterAny will call free func
      # So we don't need to remove object from STORAGE here.
      true
    end

    def lib_version
      version_ptr = ::FFI::MemoryPointer.new(:ulong)
      result = FFI::Connection.virConnectGetLibVersion(@conn_ptr, version_ptr)
      raise Error, "Couldn't get connection lib version" if result < 0
      version_number = version_ptr.get_ulong(0)
      Libvirt::Util.parse_version(version_number)
    end

    def hostname
      FFI::Connection.virConnectGetHostname(@conn_ptr)
    end

    # @param type [String,NilClass]
    def max_vcpus(type = nil)
      FFI::Connection.virConnectGetMaxVcpus(@conn_ptr, type)
    end

    def capabilities
      FFI::Connection.virConnectGetCapabilities(@conn_ptr)
    end

    def node_info
      node_info_ptr = ::FFI::MemoryPointer.new(FFI::NodeInfo::Struct.by_value)
      result = FFI::NodeInfo.virNodeGetInfo(@conn_ptr, node_info_ptr)
      raise Error, "Couldn't get connection node info" if result < 0
      NodeInfo.new(node_info_ptr)
    end

    def stream(flags = 0)
      pointer = FFI::Stream.virStreamNew(@conn_ptr, flags)
      raise Error, "Couldn't create stream" if pointer.null?
      Stream.new(pointer)
    end

    private

    def set_connection(conn_ptr)
      @conn_ptr = conn_ptr
    end

    def check_open!
      raise Error, "Connection to #{@uri.inspect} is not open" if @conn_ptr.null?
    end

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Connection', &block)
    end
  end
end
