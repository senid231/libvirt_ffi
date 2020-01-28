# frozen_string_literal: true

module Libvirt
  class NodeInfo
    def initialize(node_info_ptr)
      @node_info_ptr = node_info_ptr
      @node_info_struct = FFI::NodeInfo::Struct.new(node_info_ptr)
    end

    def [](attr)
      @node_info_struct[attr]
    end

    def model
      @node_info_struct[:model].to_s
    end

    def cpus
      @node_info_struct[:cpus]
    end

    def mhz
      @node_info_struct[:mhz]
    end

    def nodes
      @node_info_struct[:nodes]
    end

    def sockets
      @node_info_struct[:sockets]
    end

    def cores
      @node_info_struct[:cores]
    end

    def threads
      @node_info_struct[:threads]
    end

    def memory
      @node_info_struct[:memory]
    end
  end
end
