# frozen_string_literal: true

module Libvirt
  class StoragePool

    def self.load_ref(pointer)
      result = FFI::Storage.virStoragePoolRef(pointer)
      raise Errors::LibError, "Couldn't retrieve storage pool reference" if result < 0
      new(pointer)
    end

    def initialize(pointer)
      @ptr = pointer

      free = ->(obj_id) do
        Util.log(:debug) { "Finalize Libvirt::StoragePool 0x#{obj_id.to_s(16)} @ptr=#{@ptr}," }
        return unless @ptr
        fr_result = FFI::Storage.virStoragePoolFree(@ptr)
        STDERR.puts "Couldn't free Libvirt::StoragePool (0x#{obj_id.to_s(16)}) pointer #{@ptr.address}" if fr_result < 0
      end
      ObjectSpace.define_finalizer(self, free)
    end

    def to_ptr
      @ptr
    end

    def info
      info_ptr = ::FFI::MemoryPointer.new(FFI::Storage::PoolInfoStruct.by_value)
      result = FFI::Storage.virStoragePoolGetInfo(@ptr, info_ptr)
      raise Errors::LibError, "Couldn't get storage pool info" if result < 0
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
      raise Errors::LibError, "Couldn't retrieve volumes qty" if result < 0
      result
    end

    def list_all_volumes
      size = list_all_volumes_qty
      return [] if size == 0

      storage_volumes_ptr = ::FFI::MemoryPointer.new(:pointer, size)
      result = FFI::Storage.virStoragePoolListAllVolumes(@ptr, storage_volumes_ptr, 0)
      raise Errors::LibError, "Couldn't retrieve volumes list" if result < 0

      ptr = storage_volumes_ptr.read_pointer
      ptr.get_array_of_pointer(0, size).map { |stv_ptr| StorageVolume.new(stv_ptr) }
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Domain', &block)
    end
  end
end
