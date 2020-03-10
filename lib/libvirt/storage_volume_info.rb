# frozen_string_literal: true

module Libvirt
  class StorageVolumeInfo < BaseInfo
    struct_class FFI::Storage::VolumeInfoStruct
  end
end
