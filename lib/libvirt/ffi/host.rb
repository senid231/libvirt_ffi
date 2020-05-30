# frozen_string_literal: true

module Libvirt
  module FFI
    module Host
      # https://libvirt.org/html/libvirt-libvirt-host.html

      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      # struct virNodeInfo {
      #   char model[32]   model - string indicating the CPU model
      #   unsigned long   memory - memory size in kilobytes
      #   unsigned int   cpus - the number of active CPUs
      #   unsigned int   mhz - expected CPU frequency, 0 if not known or on unusual architectures
      #   unsigned int   nodes - the number of NUMA cell, 1 for unusual NUMA topologies or uniform memory access;
      #     check capabilities XML for the actual NUMA topology
      #   unsigned int   sockets - number of CPU sockets per node if nodes > 1, 1 in case of unusual NUMA topology
      #   unsigned int   cores - number of cores per socket, total number of processors in case of unusual NUMA topolog
      #   unsigned int   threads - number of threads per core, 1 in case of unusual numa topology
      # }
      class NodeInfoStruct < ::FFI::Struct
        layout :model, [:char, 32],
               :memory, :ulong,
               :cpus, :uint,
               :mhz, :uint,
               :nodes, :uint,
               :sockets, :uint,
               :cores, :uint,
               :threads, :uint
      end

      # enum virConnectCloseReason
      enum :close_reason, [
        :ERROR, 0x0, # Misc I/O error
        :EOF, 0x1, # End-of-file from server
        :KEEPALIVE, 0x2, # Keepalive timer triggered
        :CLIENT, 0x3 # Client requested it
      ]

      # int  virGetVersion  (
      #   unsigned long *libVer,
      #   const char *type,
      #   unsigned long *typeVer
      # )
      attach_function :virGetVersion, [:pointer, :string, :pointer], :int

      # int  virNodeGetInfo (
      #   virConnectPtr conn,
      #   virNodeInfoPtr info
      # )
      attach_function :virNodeGetInfo, [:pointer, :pointer], :int

      # typedef void  (*virConnectCloseFunc) (
      #   virConnectPtr conn,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectCloseFunc, [:pointer, :close_reason, :pointer], :void

      # virConnectPtr  virConnectOpen (const char * name)
      attach_function :virConnectOpen, [:string], :pointer

      # int  virConnectSetKeepAlive (
      #   virConnectPtr conn,
      #   int interval,
      #   unsigned int count
      # )
      attach_function :virConnectSetKeepAlive, [:pointer, :int, :uint], :int

      # int  virConnectGetVersion (
      #   virConnectPtr conn,
      #   unsigned long * hvVer
      # )
      attach_function :virConnectGetVersion, [:pointer, :pointer], :int

      # int  virConnectGetLibVersion  (
      #   virConnectPtr conn,
      #   unsigned long * libVer
      # )
      attach_function :virConnectGetLibVersion, [:pointer, :pointer], :int

      # char *  virConnectGetHostname  (
      #   virConnectPtr conn
      # )
      attach_function :virConnectGetHostname, [:pointer], :string # strptr ?

      # int  virConnectGetMaxVcpus  (
      #   virConnectPtr conn,
      #   const char * type
      # )
      attach_function :virConnectGetMaxVcpus, [:pointer, :string], :int

      # char *  virConnectGetCapabilities  (
      #   virConnectPtr conn
      # )
      attach_function :virConnectGetCapabilities, [:pointer], :string # strptr ?

      # int  virConnectClose  (
      #   virConnectPtr conn
      # )
      attach_function :virConnectClose, [:pointer], :int

      # int  virConnectRegisterCloseCallback  (
      #   virConnectPtr conn,
      #   virConnectCloseFunc cb,
      #   void * opaque,
      #   virFreeCallback freecb
      # )
      attach_function :virConnectRegisterCloseCallback, [
          :pointer,
          :virConnectCloseFunc,
          :pointer,
          FFI::Common::FREE_CALLBACK
      ], :int

      # int  virConnectUnregisterCloseCallback  (
      #   virConnectPtr conn,
      #   virConnectCloseFunc cb
      # )
      attach_function :virConnectUnregisterCloseCallback, [:pointer, :pointer], :int

      # int  virConnectRef  (
      #   virConnectPtr conn
      # )
      attach_function :virConnectRef, [:pointer], :int

      # unsigned long long virNodeGetFreeMemory (
      #   virConnectPtr conn
      # )
      attach_function :virNodeGetFreeMemory, [:pointer], :ulong_long
    end
  end
end
