# frozen_string_literal: true

module Libvirt
  class Connection
    include Loggable

    DOMAIN_EVENT_IDS = FFI::Domain.enum_type(:event_id).symbols.dup.freeze
    POOL_EVENT_IDS = FFI::Storage.enum_type(:event_id).symbols.dup.freeze
    NETWORK_EVENT_IDS = FFI::Network.enum_type(:event_id).symbols.dup.freeze

    DOMAIN_STORAGE = HostCallbackStorage.new(:domain_event)
    POOL_STORAGE = HostCallbackStorage.new(:storage_pool_event)
    NETWORK_STORAGE = HostCallbackStorage.new(:network_event)
    CLOSE_STORAGE = HostCallbackStorage.new(:close)

    DOMAIN_EVENT_CALLBACKS = DOMAIN_EVENT_IDS.map do |event_id_sym|
      func = FFI::Domain.event_callback_for(event_id_sym) do |conn_ptr, dom_ptr, *args, op_ptr|
        Util.log(:debug, "DOMAIN_EVENT_CALLBACKS[#{event_id_sym}]") do
          "inside callback conn_ptr=#{conn_ptr}, pool_ptr=#{dom_ptr}, args=#{args}, op_ptr=#{op_ptr}"
        end
        connection = Connection.load_ref(conn_ptr)
        domain = Domain.load_ref(dom_ptr)
        block, opaque = DOMAIN_STORAGE.retrieve_from_pointer(op_ptr)
        block.call(connection, domain, *args, opaque)
      end
      [event_id_sym, func]
    end.to_h.freeze

    POOL_EVENT_CALLBACKS = POOL_EVENT_IDS.map do |event_id_sym|
      func = FFI::Storage.event_callback_for(event_id_sym) do |conn_ptr, pool_ptr, *args, op_ptr|
        Util.log(:debug, "POOL_EVENT_CALLBACKS[#{event_id_sym}]") do
          "inside callback conn_ptr=#{conn_ptr}, pool_ptr=#{pool_ptr}, args=#{args}, op_ptr=#{op_ptr}"
        end
        connection = Connection.load_ref(conn_ptr)
        pool = StoragePool.load_ref(pool_ptr)
        block, opaque = POOL_STORAGE.retrieve_from_pointer(op_ptr)
        block.call(connection, pool, *args, opaque)
      end
      [event_id_sym, func]
    end.to_h.freeze

    NETWORK_EVENT_CALLBACKS = NETWORK_EVENT_IDS.map do |event_id_sym|
      func = FFI::Network.event_callback_for(event_id_sym) do |conn_ptr, pool_ptr, *args, op_ptr|
        Util.log(:debug, "NETWORK_EVENT_CALLBACKS[#{event_id_sym}]") do
          "inside callback conn_ptr=#{conn_ptr}, pool_ptr=#{pool_ptr}, args=#{args}, op_ptr=#{op_ptr}"
        end
        connection = Connection.load_ref(conn_ptr)
        pool = Network.load_ref(pool_ptr)
        block, opaque = NETWORK_STORAGE.retrieve_from_pointer(op_ptr)
        block.call(connection, pool, *args, opaque)
      end
      [event_id_sym, func]
    end.to_h.freeze

    CLOSE_CALLBACK = FFI::Host.callback_function(:virConnectCloseFunc) do |conn_ptr, reason, op_ptr|
      Util.log(:debug, 'CLOSE_CALLBACK') { "inside callback conn_ptr=#{conn_ptr}, reason=#{reason}, op_ptr=#{op_ptr}" }
      connection = Connection.load_ref(conn_ptr)
      block, opaque = CLOSE_STORAGE.retrieve_from_pointer(op_ptr)
      block.call(connection, reason, opaque)
    end

    def self.load_ref(ptr)
      result = FFI::Host.virConnectRef(ptr)
      raise Errors::LibError, "Couldn't retrieve connection reference" if result.negative?

      uri = FFI::Host.virConnectGetURI(ptr)
      new(uri).tap { |c| c.instance_variable_set(:@ptr, ptr) }
    end

    attr_reader :uri

    def initialize(uri)
      @uri = uri
      @ptr = ::FFI::Pointer.new(0)
      @close_data = nil

      Util.define_finalizer(self) { |pointer| FFI::Host.virConnectClose(pointer) }
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} @uri=#{@uri.inspect} @ptr=0x#{@ptr.address.to_s(16)}>"
    end

    def inspect
      to_s
    end

    def to_ptr
      @ptr
    end

    def open
      @ptr = FFI::Host.virConnectOpen(@uri)
      raise Errors::LibError, "Couldn't open connection to #{@uri.inspect}" if @ptr.null?

      dbg { 'opened' }

      true
    end

    def close
      result = FFI::Host.virConnectClose(@ptr)
      raise Errors::LibError, "Couldn't close connection to #{@uri.inspect}" if result.negative?

      dbg { 'closed' }

      @ptr = ::FFI::Pointer.new(0)
      true
    end

    def opened?
      !@ptr.null?
    end

    def closed?
      !opened?
    end

    def version
      check_open!

      version_ptr = ::FFI::MemoryPointer.new(:ulong)
      result = FFI::Host.virConnectGetVersion(@ptr, version_ptr)
      raise Errors::LibError, "Couldn't retrieve connection version" if result.negative?

      version_number = version_ptr.get_ulong(0)
      Util.parse_version(version_number)
    end

    def set_keep_alive(interval, count)
      result = FFI::Host.virConnectSetKeepAlive(@ptr, interval, count)
      raise Errors::LibError, "Couldn't set connection keep_alive" if result.negative?

      result.zero?
    end

    def free_memory
      result = FFI::Host.virNodeGetFreeMemory(@ptr)
      raise Errors::LibError, "Couldn't set connection keep_alive" if result.negative?

      result
    end

    def list_all_domains_qty(flags = 0)
      result = FFI::Domain.virConnectListAllDomains(@ptr, nil, flags)
      raise Errors::LibError, "Couldn't retrieve domains qty with flags #{flags.to_s(16)}" if result.negative?

      result
    end

    def list_all_domains(flags = 0)
      size = list_all_domains_qty(flags)
      return [] if size.zero?

      domains_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Domain.virConnectListAllDomains(@ptr, domains_ptr, flags)
      raise Errors::LibError, "Couldn't retrieve domains list with flags #{flags.to_s(16)}" if result.negative?

      ptr = domains_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |dom_ptr| Libvirt::Domain.new(dom_ptr) }
    end

    def list_all_storage_pools_qty(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Storage.enum_type(:list_all_pools_flags)
      result = FFI::Storage.virConnectListAllStoragePools(@ptr, nil, flags)
      raise Errors::LibError, "Couldn't retrieve storage pools qty with flags #{flags.to_s(16)}" if result.negative?

      result
    end

    def list_all_storage_pools(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Storage.enum_type(:list_all_pools_flags)
      size = list_all_storage_pools_qty(flags)
      return [] if size.zero?

      storage_pools_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Storage.virConnectListAllStoragePools(@ptr, storage_pools_ptr, flags)
      raise Errors::LibError, "Couldn't retrieve storage pools list with flags #{flags.to_s(16)}" if result.negative?

      ptr = storage_pools_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |stp_ptr| StoragePool.new(stp_ptr) }
    end

    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @return [Integer]
    # @raise [Libvirt::Errors::LibError]
    def list_all_networks_qty(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Network.enum_type(:list_all_flags)
      result = FFI::Network.virConnectListAllNetworks(@ptr, nil, flags)
      raise Errors::LibError, "Couldn't retrieve networks qty with flags #{flags.to_s(16)}" if result.negative?

      result
    end

    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @return [Array<Libvirt::Network>, Array]
    # @raise [Libvirt::Errors::LibError]
    def list_all_networks(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Network.enum_type(:list_all_flags)
      size = list_all_networks_qty(flags)
      return [] if size.zero?

      networks_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Network.virConnectListAllNetworks(@ptr, networks_ptr, 0)
      raise Errors::LibError, "Couldn't retrieve networks list" if result.negative?

      ptr = networks_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |n_ptr| Network.new(n_ptr) }
    end

    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @return [Integer]
    # @raise [Libvirt::Errors::LibError]
    def list_all_interfaces_qty(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Interface.enum_type(:list_all_flags)
      result = FFI::Interface.virConnectListAllInterfaces(@ptr, nil, flags)
      raise Errors::LibError, "Couldn't retrieve interfaces qty with flags #{flags.to_s(16)}" if result.negative?

      result
    end

    # @param options_or_flags [Array<Symbol>,Hash{Symbol=>Boolean},Integer,Symbol,nil]
    # @return [Array<Libvirt::Interface>, Array]
    # @raise [Libvirt::Errors::LibError]
    def list_all_interfaces(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Interface.enum_type(:list_all_flags)
      size = list_all_interfaces_qty(flags)
      return [] if size.zero?

      interfaces_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Interface.virConnectListAllInterfaces(@ptr, interfaces_ptr, 0)
      raise Errors::LibError, "Couldn't retrieve interfaces list" if result.negative?

      ptr = interfaces_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |i_ptr| Interface.new(i_ptr) }
    end

    def register_close_callback(opaque = nil, &block)
      dbg { "opaque=#{opaque}" }

      cb_data, cb_data_free_func = CLOSE_STORAGE.allocate_struct
      result = FFI::Host.virConnectRegisterCloseCallback(
          @ptr,
          CLOSE_CALLBACK,
          cb_data.pointer,
          cb_data_free_func
      )
      if result.negative?
        cb_data.pointer.free
        raise Errors::LibError, "Couldn't register connection close callback"
      end

      CLOSE_STORAGE.store_struct(
          cb_data,
          connection_pointer: @ptr,
          callback_id: result,
          cb: block,
          opaque: opaque,
          free_func: cb_data_free_func
      )
      result
    end

    def deregister_close_callback
      dbg { 'deregister' }

      result = FFI::Host.virConnectUnregisterCloseCallback(@ptr, CLOSE_CALLBACK)
      raise Errors::LibError, "Couldn't deregister close callback" if result.negative?

      # virConnectUnregisterCloseCallback will call free func
      # So we don't need to remove object from CLOSE_STORAGE here.
      true
    end

    # @yield conn, dom, *args
    def register_domain_event_callback(event_id, domain = nil, opaque = nil, &block)
      dbg { "event_id=#{event_id}" }

      enum = FFI::Domain.enum_type(:event_id)
      event_id, event_id_sym = Util.parse_enum(enum, event_id)
      cb = DOMAIN_EVENT_CALLBACKS.fetch(event_id_sym)

      cb_data, cb_data_free_func = DOMAIN_STORAGE.allocate_struct

      result = FFI::Domain.virConnectDomainEventRegisterAny(
          @ptr,
          domain&.to_ptr,
          event_id,
          cb,
          cb_data.pointer,
          cb_data_free_func
      )
      if result.negative?
        cb_data.pointer.free
        raise Errors::LibError, "Couldn't register domain event callback"
      end

      DOMAIN_STORAGE.store_struct(
          cb_data,
          connection_pointer: @conn_ptr,
          callback_id: result,
          cb: block,
          opaque: opaque,
          free_func: cb_data_free_func
      )
      result
    end

    def deregister_domain_event_callback(callback_id)
      dbg { "callback_id=#{callback_id}" }

      result = FFI::Domain.virConnectDomainEventDeregisterAny(@ptr, callback_id)
      raise Errors::LibError, "Couldn't deregister domain event callback" if result.negative?

      # virConnectDomainEventDeregisterAny will call free func
      # So we don't need to remove object from DOMAIN_STORAGE here.
      true
    end

    def register_storage_pool_event_callback(event_id, storage_pool = nil, opaque = nil, &block)
      dbg { "event_id=#{event_id}" }

      enum = FFI::Storage.enum_type(:event_id)
      event_id, event_id_sym = Util.parse_enum(enum, event_id)
      cb = POOL_EVENT_CALLBACKS.fetch(event_id_sym)

      cb_data, cb_data_free_func = POOL_STORAGE.allocate_struct

      result = FFI::Storage.virConnectStoragePoolEventRegisterAny(
          @ptr,
          storage_pool&.to_ptr,
          event_id,
          cb,
          cb_data.pointer,
          cb_data_free_func
      )
      if result.negative?
        cb_data.pointer.free
        raise Errors::LibError, "Couldn't register storage pool event callback"
      end

      POOL_STORAGE.store_struct(
          cb_data,
          connection_pointer: @ptr,
          callback_id: result,
          cb: block,
          opaque: opaque,
          free_func: cb_data_free_func
      )
      result
    end

    def deregister_storage_pool_event_callback(callback_id)
      dbg { "callback_id=#{callback_id}" }

      result = FFI::Storage.virConnectStoragePoolEventDeregisterAny(@ptr, callback_id)
      raise Errors::LibError, "Couldn't deregister storage pool event callback" if result.negative?

      # virConnectStoragePoolEventDeregisterAny will call free func
      # So we don't need to remove object from POOL_STORAGE here.
      true
    end

    def register_network_event_callback(event_id, network = nil, opaque = nil, &block)
      dbg { "event_id=#{event_id}" }

      enum = FFI::Network.enum_type(:event_id)
      event_id, event_id_sym = Util.parse_enum(enum, event_id)
      cb = NETWORK_EVENT_CALLBACKS.fetch(event_id_sym)

      cb_data, cb_data_free_func = NETWORK_STORAGE.allocate_struct

      result = FFI::Network.virConnectNetworkEventRegisterAny(
          @ptr,
          network&.to_ptr,
          event_id,
          cb,
          cb_data.pointer,
          cb_data_free_func
      )
      if result.negative?
        cb_data.pointer.free
        raise Errors::LibError, "Couldn't register network event callback"
      end

      NETWORK_STORAGE.store_struct(
          cb_data,
          connection_pointer: @ptr,
          callback_id: result,
          cb: block,
          opaque: opaque,
          free_func: cb_data_free_func
      )
      result
    end

    def deregister_network_event_callback(callback_id)
      dbg { "callback_id=#{callback_id}" }

      result = FFI::Network.virConnectNetworkEventDeregisterAny(@ptr, callback_id)
      raise Errors::LibError, "Couldn't deregister network event callback" if result.negative?

      # virConnectNetworkEventDeregisterAny will call free func
      # So we don't need to remove object from NETWORK_STORAGE here.
      true
    end

    def lib_version
      version_ptr = ::FFI::MemoryPointer.new(:ulong)
      result = FFI::Host.virConnectGetLibVersion(@ptr, version_ptr)
      raise Errors::LibError, "Couldn't get connection lib version" if result.negative?

      version_number = version_ptr.get_ulong(0)
      Util.parse_version(version_number)
    end

    def hostname
      FFI::Host.virConnectGetHostname(@ptr)
    end

    # @param type [String,NilClass]
    def max_vcpus(type = nil)
      FFI::Host.virConnectGetMaxVcpus(@ptr, type)
    end

    def capabilities
      FFI::Host.virConnectGetCapabilities(@ptr)
    end

    def node_info
      node_info_ptr = ::FFI::MemoryPointer.new(FFI::Host::NodeInfoStruct.by_value)
      result = FFI::Host.virNodeGetInfo(@ptr, node_info_ptr)
      raise Errors::LibError, "Couldn't get connection node info" if result.negative?

      NodeInfo.new(node_info_ptr)
    end

    def stream(flags = 0)
      pointer = FFI::Stream.virStreamNew(@ptr, flags)
      raise Errors::LibError, "Couldn't create stream" if pointer.null?

      Stream.new(pointer)
    end

    def define_domain(xml, options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Domain.enum_type(:define_flags)
      pointer = FFI::Domain.virDomainDefineXMLFlags(@ptr, xml, flags)
      raise Errors::LibError, "Couldn't define domain" if pointer.null?

      Domain.new(pointer)
    end

    # @param xml [String]
    # @raise [Libvirt::Errors::LibError]
    def create_network(xml)
      pointer = FFI::Network.virNetworkCreateXML(@ptr, xml)
      raise Errors::LibError, "Couldn't create network with xml" if pointer.null?

      Network.new(pointer)
    end

    # @param xml [String]
    # @raise [Libvirt::Errors::LibError]
    def define_network(xml)
      pointer = FFI::Network.virNetworkDefineXML(@ptr, xml)
      raise Errors::LibError, "Couldn't define network with xml" if pointer.null?

      Network.new(pointer)
    end

    # @param xml [String]
    # @raise [Libvirt::Errors::LibError]
    def define_interface(xml)
      pointer = FFI::Interface.virInterfaceDefineXML(@ptr, xml, 0)
      raise Errors::LibError, "Couldn't define interface with xml" if pointer.null?

      Interface.new(pointer)
    end

    # @raise [Libvirt::Errors::LibError]
    def begin_interface_change
      result = FFI::Interface.virInterfaceChangeBegin(@ptr, 0)
      raise Errors::LibError, "Couldn't begin interface change" if result.negative?
    end

    # @raise [Libvirt::Errors::LibError]
    def commit_interface_change
      result = FFI::Interface.virInterfaceChangeCommit(@ptr, 0)
      raise Errors::LibError, "Couldn't commit interface change" if result.negative?
    end

    # @raise [Libvirt::Errors::LibError]
    def rollback_interface_change
      result = FFI::Interface.virInterfaceChangeRollback(@ptr, 0)
      raise Errors::LibError, "Couldn't rollback interface change" if result.negative?
    end

    private

    def check_open!
      raise Errors::LibError, "Connection to #{@uri.inspect} is not open" if @ptr.null?
    end
  end
end
