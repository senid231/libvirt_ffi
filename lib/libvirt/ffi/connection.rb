# frozen_string_literal: true

module Libvirt
  module FFI
    module Connection
      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      # struct virNodeInfo {
      #
      #   char model[32] 	model - string indicating the CPU model
      #   unsigned long 	memory - memory size in kilobytes
      #   unsigned int 	cpus - the number of active CPUs
      #   unsigned int 	mhz - expected CPU frequency, 0 if not known or on unusual architectures
      #   unsigned int 	nodes - the number of NUMA cell, 1 for unusual NUMA topologies or uniform memory access; check capabilities XML for the actual NUMA topology
      #   unsigned int 	sockets - number of CPU sockets per node if nodes > 1, 1 in case of unusual NUMA topology
      #   unsigned int 	cores - number of cores per socket, total number of processors in case of unusual NUMA topolog
      #   unsigned int 	threads - number of threads per core, 1 in case of unusual numa topology
      # }
      class NodeInfoStruct < ::FFI::Struct
        layout :model, [:char, 32],
               :memory, :ulong,
               :cpus, :ulong,
               :mhz, :ulong,
               :nodes, :ulong,
               :sockets, :ulong,
               :cores, :ulong,
               :threads, :ulong
      end

      class NodeInfo
        def initialize(node_info_ptr, node_info_struct)
          @node_info_ptr = node_info_ptr
          @node_info_struct = node_info_struct
        end

        def [](attr)
          @node_info_struct[attr]
        end
      end

      # typedef void	(*virConnectCloseFunc) (
      #   virConnectPtr conn,
      # 	int reason,
      # 	void * opaque
      # )
      callback :virConnectCloseFunc, [:pointer, :int, :pointer], :void

      # virConnectPtr	virConnectOpen (const char * name)
      attach_function :virConnectOpen, [:string], :pointer

      # int	virConnectGetVersion (virConnectPtr conn, unsigned long *hvVer)
      attach_function :virConnectGetVersion, [:pointer, :pointer], :int

      # int	virConnectSetKeepAlive (
      #   virConnectPtr conn,
      # 	int interval,
      # 	unsigned int count
      # )
      attach_function :virConnectSetKeepAlive, [:pointer, :int, :uint], :int

      # int	virConnectGetVersion (
      #   virConnectPtr conn,
      # 	unsigned long * hvVer
      # )
      attach_function :virConnectGetVersion, [:pointer, :pointer], :int

      # int	virConnectGetLibVersion	(
      #   virConnectPtr conn,
      # 	unsigned long * libVer
      # )
      attach_function :virConnectGetLibVersion, [:pointer, :pointer], :int

      # char *	virConnectGetHostname	(
      #   virConnectPtr conn
      # )
      attach_function :virConnectGetHostname, [:pointer], :string # strptr ?

      # int	virConnectGetMaxVcpus	(
      #   virConnectPtr conn,
      #   const char * type
      # )
      attach_function :virConnectGetMaxVcpus, [:pointer, :string], :int

      # char *	virConnectGetCapabilities	(
      #   virConnectPtr conn
      # )
      attach_function :virConnectGetCapabilities, [:pointer],  :string # strptr ?

      # int	virConnectClose	(
      #   virConnectPtr conn
      # )
      attach_function :virConnectClose, [:pointer], :int

      # int	virConnectRegisterCloseCallback	(
      #   virConnectPtr conn,
      # 	virConnectCloseFunc cb,
      # 	void * opaque,
      # 	virFreeCallback freecb
      # )
      attach_function :virConnectRegisterCloseCallback, [
          :pointer,
          :virConnectCloseFunc,
          :pointer,
          FFI::Common::FREE_CALLBACK
      ], :int

      # int	virConnectUnregisterCloseCallback	(
      #   virConnectPtr conn,
      # 	virConnectCloseFunc cb
      # )
      attach_function :virConnectUnregisterCloseCallback, [:pointer, :pointer], :int

      # int	virConnectRef	(
      #   virConnectPtr conn
      # )
      attach_function :virConnectRef, [:pointer], :int
    end
  end
end
