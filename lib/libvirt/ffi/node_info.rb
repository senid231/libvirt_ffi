# frozen_string_literal: true

module Libvirt
  module FFI
    module NodeInfo
      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      # struct virNodeInfo {
      #
      #   char model[32] 	model - string indicating the CPU model
      #   unsigned long 	memory - memory size in kilobytes
      #   unsigned int 	cpus - the number of active CPUs
      #   unsigned int 	mhz - expected CPU frequency, 0 if not known or on unusual architectures
      #   unsigned int 	nodes - the number of NUMA cell, 1 for unusual NUMA topologies or uniform memory access;
      #     check capabilities XML for the actual NUMA topology
      #   unsigned int 	sockets - number of CPU sockets per node if nodes > 1, 1 in case of unusual NUMA topology
      #   unsigned int 	cores - number of cores per socket, total number of processors in case of unusual NUMA topolog
      #   unsigned int 	threads - number of threads per core, 1 in case of unusual numa topology
      # }
      class Struct < ::FFI::Struct
        layout :model, [:char, 32],
               :memory, :ulong,
               :cpus, :uint,
               :mhz, :uint,
               :nodes, :uint,
               :sockets, :uint,
               :cores, :uint,
               :threads, :uint
      end

      # int	virNodeGetInfo			(virConnectPtr conn,
      # 					 virNodeInfoPtr info)
      attach_function :virNodeGetInfo, [:pointer, :pointer], :int
    end
  end
end
