# frozen_string_literal: true

module Libvirt
  class StoragePool
    def self.load_ref(pointer)
      result = FFI::Storage.virStoragePoolRef(pointer)
      raise Errors::LibError, "Couldn't retrieve storage pool reference" if result.negative?

      new(pointer)
    end

    def initialize(pointer)
      @ptr = pointer

      free = ->(obj_id) do
        dbg { "Finalize Libvirt::StoragePool 0x#{obj_id.to_s(16)} @ptr=#{@ptr}," }
        return unless @ptr

        fr_result = FFI::Storage.virStoragePoolFree(@ptr)
        warn "Couldn't free Libvirt::StoragePool (0x#{obj_id.to_s(16)}) pointer #{@ptr.address}" if fr_result.negative?
      end
      ObjectSpace.define_finalizer(self, free)
    end

    def to_ptr
      @ptr
    end

    def info
      info_ptr = ::FFI::MemoryPointer.new(FFI::Storage::PoolInfoStruct.by_value)
      result = FFI::Storage.virStoragePoolGetInfo(@ptr, info_ptr)
      raise Errors::LibError, "Couldn't get storage pool info" if result.negative?

      StoragePoolInfo.new(info_ptr)
    end

    def xml_desc(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Storage.enum_type(:xml_flags)
      result = FFI::Storage.virStoragePoolGetXMLDesc(@ptr, flags)
      raise Errors::LibError, "Couldn't get storage pool xml desc" if result.nil?

      result
    end

    def list_all_volumes_qty
      result = FFI::Storage.virStoragePoolListAllVolumes(@ptr, nil, 0)
      raise Errors::LibError, "Couldn't retrieve volumes qty" if result.negative?

      result
    end

    def list_all_volumes
      size = list_all_volumes_qty
      return [] if size.zero?

      storage_volumes_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Storage.virStoragePoolListAllVolumes(@ptr, storage_volumes_ptr, 0)
      raise Errors::LibError, "Couldn't retrieve volumes list" if result.negative?

      ptr = storage_volumes_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |stv_ptr| StorageVolume.new(stv_ptr) }
    end

    def uuid
      buff = ::FFI::MemoryPointer.new(:char, Util::UUID_STRING_BUFLEN)
      result = FFI::Storage.virStoragePoolGetUUIDString(@ptr, buff)
      raise Errors::LibError, "Couldn't get storage pool uuid" if result.negative?

      buff.read_string
    end

    def name
      result = FFI::Storage.virStoragePoolGetName(@ptr)
      raise Errors::LibError, "Couldn't retrieve storage pool name" if result.nil?

      result
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::StoragePool', &block)
    end
  end
end
