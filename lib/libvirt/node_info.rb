# frozen_string_literal: true

module Libvirt
  class NodeInfo < BaseInfo
    struct_class FFI::Host::NodeInfoStruct
  end
end
