# frozen_string_literal: true

module Libvirt
  module FFI
    module Storage
      # https://libvirt.org/html/libvirt-libvirt-storage.html

      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      EVENT_ID_TO_CALLBACK = {
          LIFECYCLE: :virConnectStoragePoolEventLifecycleCallback,
          REFRESH: :virConnectStoragePoolEventGenericCallback
      }.freeze

      # enum virStoragePoolState
      enum :pool_state, [
          :INACTIVE, 0x0, # Not running
          :BUILDING, 0x1, # Initializing pool, not available
          :RUNNING, 0x2, # Running normally
          :DEGRADED, 0x3, # Running degraded
          :INACCESSIBLE, 0x4 # Running, but not accessible
      ]

      # enum virConnectListAllStoragePoolsFlags
      enum :list_all_pools_flags, [
          :INACTIVE, 0x1,
          :ACTIVE, 0x2,
          :PERSISTENT, 0x4,
          :TRANSIENT, 0x8,
          :AUTOSTART, 0x10,
          :NO_AUTOSTART, 0x20, # List pools by type
          :DIR, 0x40,
          :FS, 0x80,
          :NETFS, 0x100,
          :LOGICAL, 0x200,
          :DISK, 0x400,
          :ISCSI, 0x800,
          :SCSI, 0x1000,
          :MPATH, 0x2000,
          :RBD, 0x4000,
          :SHEEPDOG, 0x8000,
          :GLUSTER, 0x10000,
          :ZFS, 0x20000,
          :VSTORAGE, 0x40000,
          :ISCSI_DIRECT, 0x80000
      ]

      # enum virStorageVolInfoFlags
      enum :volume_info_flags, [
          :USE_ALLOCATION, 0x0, # Return the physical size in allocation
          :GET_PHYSICAL, 0x1
      ]

      # enum virStorageVolType
      enum :volume_type, [
          :FILE, 0x0, # Regular file based volumes
          :BLOCK, 0x1, # Block based volumes
          :DIR, 0x2, # Directory-passthrough based volume
          :NETWORK, 0x3, # Network volumes like RBD (RADOS Block Device)
          :NETDIR, 0x4, # Network accessible directory that can contain other network volumes
          :PLOOP, 0x5 # Ploop based volumes
      ]

      # enum virStorageXMLFlags
      enum :xml_flags, [
          :INACTIVE, 0x1 # dump inactive pool/volume information
      ]

      # enum virStoragePoolEventID
      enum :event_id, [
          :LIFECYCLE, 0x0, # virConnectStoragePoolEventLifecycleCallback
          :REFRESH, 0x1 # virConnectStoragePoolEventGenericCallback
      ]

      # enum virStoragePoolEventLifecycleType
      enum :event_lifecycle_type, [
          :DEFINED, 0x0,
          :UNDEFINED, 0x1,
          :STARTED, 0x2,
          :STOPPED, 0x3,
          :CREATED, 0x4,
          :DELETED, 0x5,
          :LAST, 0x6
      ]

      # struct virStoragePoolInfo {
      #   int   state #   virStoragePoolState flags
      #   unsigned long long   capacity #   Logical size bytes
      #   unsigned long long   allocation #   Current allocation bytes
      #   unsigned long long   available #   Remaining free space bytes
      # }
      class PoolInfoStruct < ::FFI::Struct
        layout :state, FFI::Storage.enum_type(:pool_state),
               :capacity, :ulong_long,
               :allocation, :ulong_long,
               :available, :ulong_long
      end

      # struct virStorageVolInfo {
      #   int   type #   virStorageVolType flags
      #   unsigned long long   capacity #   Logical size bytes
      #   unsigned long long   allocation #   Current allocation bytes
      # }
      class VolumeInfoStruct < ::FFI::Struct
        layout :type, FFI::Storage.enum_type(:volume_type),
               :capacity, :ulong_long,
               :allocation, :ulong_long
      end

      # typedef void (*virConnectStoragePoolEventGenericCallback) (
      #   virConnectPtr conn,
      #   virStoragePoolPtr pool,
      #   void * opaque
      # )
      callback :virConnectStoragePoolEventGenericCallback,
               [:pointer, :pointer, :pointer],
               :void

      # typedef void (*virConnectStoragePoolEventLifecycleCallback) (
      #   virConnectPtr conn,
      #   virStoragePoolPtr pool,
      #   int event,
      #   int detail,
      #   void * opaque
      # )
      callback :virConnectStoragePoolEventLifecycleCallback,
               [:pointer, :pointer, :event_lifecycle_type, :int, :pointer],
               :void

      # int  virConnectListAllStoragePools (
      #   virConnectPtr conn,
      #   virStoragePoolPtr ** pools,
      #   unsigned int flags
      # )
      attach_function :virConnectListAllStoragePools, [:pointer, :pointer, :uint], :int

      # int  virStoragePoolGetInfo  (
      #   virStoragePoolPtr pool,
      #   virStoragePoolInfoPtr info
      # )
      attach_function :virStoragePoolGetInfo, [:pointer, :pointer], :int

      # char *  virStoragePoolGetXMLDesc  (
      #   virStoragePoolPtr pool,
      #   unsigned int flags
      # )
      attach_function :virStoragePoolGetXMLDesc, [:pointer, :xml_flags], :string

      # int  virStoragePoolRef  (
      #   virStoragePoolPtr pool
      # )
      attach_function :virStoragePoolRef, [:pointer], :int

      # int  virStoragePoolFree  (
      #   virStoragePoolPtr pool
      # )
      attach_function :virStoragePoolFree, [:pointer], :int

      # int  virStoragePoolListAllVolumes (
      #   virStoragePoolPtr pool,
      #   virStorageVolPtr ** vols,
      #   unsigned int flags
      # )
      attach_function :virStoragePoolListAllVolumes, [:pointer, :pointer, :uint], :int

      # int  virStorageVolRef (
      #   virStorageVolPtr vol
      # )
      attach_function :virStorageVolRef, [:pointer], :int

      # int  virStorageVolFree (
      #   virStorageVolPtr vol
      # )
      attach_function :virStorageVolFree, [:pointer], :int

      # int  virStorageVolGetInfo (
      #   virStorageVolPtr vol,
      #   virStorageVolInfoPtr info
      # )
      attach_function :virStorageVolGetInfo, [:pointer, :pointer], :int

      # char * virStorageVolGetXMLDesc (
      #   virStorageVolPtr vol,
      #   unsigned int flags
      # )
      attach_function :virStorageVolGetXMLDesc, [:pointer, :xml_flags], :string

      # int  virConnectStoragePoolEventRegisterAny (
      #   virConnectPtr conn,
      #   virStoragePoolPtr pool,
      #   int eventID,
      #   virConnectStoragePoolEventGenericCallback cb,
      #   void * opaque,
      #   virFreeCallback freecb
      # )
      attach_function :virConnectStoragePoolEventRegisterAny,
                      [:pointer, :pointer, :event_id, :pointer, :pointer, FFI::Common::FREE_CALLBACK],
                      :int

      # int  virConnectStoragePoolEventDeregisterAny (
      #   virConnectPtr conn,
      #   int callbackID
      # )
      attach_function :virConnectStoragePoolEventDeregisterAny,
                      [:pointer, :int],
                      :int

      # int  virStoragePoolGetUUIDString  (virStoragePoolPtr pool,
      #            char * buf)
      attach_function :virStoragePoolGetUUIDString, [:pointer, :pointer], :int

      # const char *  virStoragePoolGetName  (virStoragePoolPtr pool)
      attach_function :virStoragePoolGetName, [:pointer], :string

      module_function

      # Creates event callback function for provided event_id
      # @param event_id [Integer,Symbol]
      # @yield connect_ptr, domain_ptr, *args, opaque_ptr
      # @return [FFI::Function]
      def event_callback_for(event_id, &block)
        event_id_sym = event_id.is_a?(Symbol) ? event_id : enum_type(:event_id)[event_id]

        callback_name = EVENT_ID_TO_CALLBACK.fetch(event_id_sym)
        callback_function(callback_name) do |*args|
          Util.log(:debug, name) { ".event_callback_for #{event_id_sym} CALLBACK #{args.map(&:to_s).join(', ')}," }
          block.call(*args)
        end
      end
    end
  end
end
