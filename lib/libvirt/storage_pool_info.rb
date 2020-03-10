# frozen_string_literal: true

module Libvirt
  class StoragePoolInfo < BaseInfo
    struct_class FFI::Storage::PoolInfoStruct
  end
end
