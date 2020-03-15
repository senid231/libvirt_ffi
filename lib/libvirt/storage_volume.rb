# frozen_string_literal: true

module Libvirt
  class StorageVolume
    def self.load_ref(pointer)
      result = FFI::Storage.virStorageVolRef(pointer)
      raise Errors::LibError, "Couldn't retrieve storage volume reference" if result.negative?

      new(pointer)
    end

    def initialize(pointer)
      @ptr = pointer

      free = ->(obj_id) do
        Util.log(:debug) { "Finalize Libvirt::StorageVolume 0x#{obj_id.to_s(16)} @ptr=#{@ptr}," }
        return unless @ptr

        fr_result = FFI::Storage.virStorageVolFree(@ptr)
        warn "Couldn't free Libvirt::StorageVolume (0x#{obj_id.to_s(16)}) pointer #{@ptr.address}" if fr_result.negative?
      end
      ObjectSpace.define_finalizer(self, free)
    end

    def to_ptr
      @ptr
    end

    def info
      info_ptr = ::FFI::MemoryPointer.new(FFI::Storage::VolumeInfoStruct.by_value)
      result = FFI::Storage.virStorageVolGetInfo(@ptr, info_ptr)
      raise Errors::LibError, "Couldn't get storage volume info" if result.negative?

      StorageVolumeInfo.new(info_ptr)
    end

    def xml_desc(options_or_flags = nil)
      flags = Util.parse_flags options_or_flags, FFI::Storage.enum_type(:xml_flags)
      result = FFI::Storage.virStorageVolGetXMLDesc(@ptr, flags)
      raise Errors::LibError, "Couldn't get storage volume xml desc" if result.nil?

      result
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Domain', &block)
    end
  end
end
