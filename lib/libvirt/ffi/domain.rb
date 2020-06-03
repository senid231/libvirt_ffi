# frozen_string_literal: true

module Libvirt
  module FFI
    module Domain
      # https://libvirt.org/html/libvirt-libvirt-domain.html

      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      EVENT_ID_TO_CALLBACK = {
          LIFECYCLE: :virConnectDomainEventCallback,
          REBOOT: :virConnectDomainEventGenericCallback,
          RTC_CHANGE: :virConnectDomainEventRTCChangeCallback,
          WATCHDOG: :virConnectDomainEventWatchdogCallback,
          IO_ERROR: :virConnectDomainEventIOErrorCallback,
          GRAPHICS: :virConnectDomainEventGraphicsCallback,
          IO_ERROR_REASON: :virConnectDomainEventIOErrorReasonCallback,
          CONTROL_ERROR: :virConnectDomainEventGenericCallback,
          BLOCK_JOB: :virConnectDomainEventBlockJobCallback,
          DISK_CHANGE: :virConnectDomainEventDiskChangeCallback,
          TRAY_CHANGE: :virConnectDomainEventTrayChangeCallback,
          PMWAKEUP: :virConnectDomainEventPMWakeupCallback,
          PMSUSPEND: :virConnectDomainEventPMSuspendCallback,
          BALLOON_CHANGE: :virConnectDomainEventBalloonChangeCallback,
          PMSUSPEND_DISK: :virConnectDomainEventPMSuspendDiskCallback,
          DEVICE_REMOVED: :virConnectDomainEventDeviceRemovedCallback,
          BLOCK_JOB_2: :virConnectDomainEventBlockJobCallback,
          TUNABLE: :virConnectDomainEventTunableCallback,
          AGENT_LIFECYCLE: :virConnectDomainEventAgentLifecycleCallback,
          DEVICE_ADDED: :virConnectDomainEventDeviceAddedCallback,
          MIGRATION_ITERATION: :virConnectDomainEventMigrationIterationCallback,
          JOB_COMPLETED: :virConnectDomainEventJobCompletedCallback,
          DEVICE_REMOVAL_FAILED: :virConnectDomainEventDeviceRemovalFailedCallback,
          METADATA_CHANGE: :virConnectDomainEventMetadataChangeCallback,
          BLOCK_THRESHOLD: :virConnectDomainEventBlockThresholdCallback
      }.freeze

      # enum virDomainEventID
      enum :event_id, [
          :LIFECYCLE, 0x0, # virConnectDomainEventCallback
          :REBOOT, 0x1, # virConnectDomainEventGenericCallback
          :RTC_CHANGE, 0x2, # virConnectDomainEventRTCChangeCallback
          :WATCHDOG, 0x3, # virConnectDomainEventWatchdogCallback
          :IO_ERROR, 0x4, # virConnectDomainEventIOErrorCallback
          :GRAPHICS, 0x5, # virConnectDomainEventGraphicsCallback
          :IO_ERROR_REASON, 0x6, # virConnectDomainEventIOErrorReasonCallback
          :CONTROL_ERROR, 0x7, # virConnectDomainEventGenericCallback
          :BLOCK_JOB, 0x8, # virConnectDomainEventBlockJobCallback
          :DISK_CHANGE, 0x9, # virConnectDomainEventDiskChangeCallback
          :TRAY_CHANGE, 0xa, # virConnectDomainEventTrayChangeCallback
          :PMWAKEUP, 0xb, # virConnectDomainEventPMWakeupCallback
          :PMSUSPEND, 0xc, # virConnectDomainEventPMSuspendCallback
          :BALLOON_CHANGE, 0xd, # virConnectDomainEventBalloonChangeCallback
          :PMSUSPEND_DISK, 0xe, # virConnectDomainEventPMSuspendDiskCallback
          :DEVICE_REMOVED, 0xf, # virConnectDomainEventDeviceRemovedCallback
          :BLOCK_JOB_2, 0x10, # virConnectDomainEventBlockJobCallback
          :TUNABLE, 0x11, # virConnectDomainEventTunableCallback
          :AGENT_LIFECYCLE, 0x12, # virConnectDomainEventAgentLifecycleCallback
          :DEVICE_ADDED, 0x13, # virConnectDomainEventDeviceAddedCallback
          :MIGRATION_ITERATION, 0x14, # virConnectDomainEventMigrationIterationCallback
          :JOB_COMPLETED, 0x15, # virConnectDomainEventJobCompletedCallback
          :DEVICE_REMOVAL_FAILED, 0x16, # virConnectDomainEventDeviceRemovalFailedCallback
          :METADATA_CHANGE, 0x17, # virConnectDomainEventMetadataChangeCallback
          :BLOCK_THRESHOLD, 0x18 # virConnectDomainEventBlockThresholdCallback
      ]

      # enum virDomainState
      enum :state, [
          :NOSTATE, 0x0, # no state
          :RUNNING, 0x1, # the domain is running
          :BLOCKED, 0x2, # the domain is blocked on resource
          :PAUSED, 0x3, # the domain is paused by user
          :SHUTDOWN, 0x4, # the domain is being shut down
          :SHUTOFF, 0x5, # the domain is shut off
          :CRASHED, 0x6, # the domain is crashed
          :PMSUSPENDED, 0x7 # the domain is suspended by guest power management
      ]

      # enum virDomainNostateReason
      enum :nostate_reason, [
          :UNKNOWN, 0x0
      ]

      # enum virDomainRunningReason
      enum :running_reason, [
          :UNKNOWN, 0x0,
          :BOOTED, 0x1, # normal startup from boot
          :MIGRATED, 0x2, # migrated from another host
          :RESTORED, 0x3, # restored from a state file
          :FROM_SNAPSHOT, 0x4, # restored from snapshot
          :UNPAUSED, 0x5, # returned from paused state
          :MIGRATION_CANCELED, 0x6, # returned from migration
          :SAVE_CANCELED, 0x7, # returned from failed save process
          :WAKEUP, 0x8, # returned from pmsuspended due to wakeup event
          :CRASHED, 0x9, # resumed from crashed
          :POSTCOPY, 0xa # running in post-copy migration mode
      ]

      # enum virDomainBlockedReason
      enum :blocked_reason, [
          :UNKNOWN, 0x0 # the reason is unknown
      ]

      # enum virDomainPausedReason
      enum :paused_reason, [
          :UNKNOWN, 0x0, # the reason is unknown
          :USER, 0x1, # paused on user request
          :MIGRATION, 0x2, # paused for offline migration
          :SAVE, 0x3, # paused for save
          :DUMP, 0x4, # paused for offline core dump
          :IOERROR, 0x5, # paused due to a disk I/O error
          :WATCHDOG, 0x6, # paused due to a watchdog event
          :FROM_SNAPSHOT, 0x7, # paused after restoring from snapshot
          :SHUTTING_DOWN, 0x8, # paused during shutdown process
          :SNAPSHOT, 0x9, # paused while creating a snapshot
          :CRASHED, 0xa, # paused due to a guest crash
          :STARTING_UP, 0xb, # the domain is being started
          :POSTCOPY, 0xc, # paused for post-copy migration
          :POSTCOPY_FAILED, 0xd # paused after failed post-copy
      ]

      # enum virDomainShutdownReason
      enum :shutdown_reason, [
          :UNKNOWN, 0x0, # the reason is unknown
          :USER, 0x1 # shutting down on user request
      ]

      # enum virDomainShutoffReason
      enum :shutoff_reason, [
          :UNKNOWN, 0x0, # the reason is unknown
          :SHUTDOWN, 0x1, # normal shutdown
          :DESTROYED, 0x2, # forced poweroff
          :CRASHED, 0x3, # domain crashed
          :MIGRATED, 0x4, # migrated to another host
          :SAVED, 0x5, # saved to a file
          :FAILED, 0x6, # domain failed to start
          :FROM_SNAPSHOT, 0x7, # restored from a snapshot which was taken while domain was shutoff
          :DAEMON, 0x8 # daemon decides to kill domain during reconnection processing
      ]

      # enum virDomainCrashedReason
      enum :crashed_reason, [
          :UNKNOWN, 0x0, # crashed for unknown reason
          :PANICKED, 0x1 # domain panicked
      ]

      # enum virDomainPMSuspendedReason
      enum :pmsuspended_reason, [
          :UNKNOWN, 0x0
      ]

      # enum virDomainEventType
      enum :event_type, [
          :DEFINED, 0x0,
          :UNDEFINED, 0x1,
          :STARTED, 0x2,
          :SUSPENDED, 0x3,
          :RESUMED, 0x4,
          :STOPPED, 0x5,
          :SHUTDOWN, 0x6,
          :PMSUSPENDED, 0x7,
          :CRASHED, 0x8
      ]

      # enum virDomainEventDefinedDetailType
      enum :event_defined_detail_type, [
          :ADDED, 0x0, # Newly created config file
          :UPDATED, 0x1, # Changed config file
          :RENAMED, 0x2, # Domain was renamed
          :FROM_SNAPSHOT, 0x3 # Config was restored from a snapshot
      ]

      # enum virDomainEventUndefinedDetailType
      enum :event_undefined_detail_type, [
          :REMOVED, 0x0, # Deleted the config file
          :RENAMED, 0x1 # Domain was renamed
      ]

      # enum virDomainEventStartedDetailType
      enum :event_started_detail_type, [
          :BOOTED, 0x0, # Normal startup from boot
          :MIGRATED, 0x1, # Incoming migration from another host
          :RESTORED, 0x2, # Restored from a state file
          :FROM_SNAPSHOT, 0x3, # Restored from snapshot
          :WAKEUP, 0x4 # Started due to wakeup event
      ]

      # enum virDomainEventSuspendedDetailType
      enum :event_suspended_detail_type, [
          :PAUSED, 0x0, # Normal suspend due to admin pause
          :MIGRATED, 0x1, # Suspended for offline migration
          :IOERROR, 0x2, # Suspended due to a disk I/O error
          :WATCHDOG, 0x3, # Suspended due to a watchdog firing
          :RESTORED, 0x4, # Restored from paused state file
          :FROM_SNAPSHOT, 0x5, # Restored from paused snapshot
          :API_ERROR, 0x6, # suspended after failure during libvirt API call
          :POSTCOPY, 0x7, # suspended for post-copy migration
          :POSTCOPY_FAILED, 0x8 # suspended after failed post-copy
      ]

      # enum virDomainEventResumedDetailType
      enum :event_resumed_detail_type, [
          :UNPAUSED, 0x0, # Normal resume due to admin unpause
          :MIGRATED, 0x1, # Resumed for completion of migration
          :FROM_SNAPSHOT, 0x2, # Resumed from snapshot
          :POSTCOPY, 0x3 # Resumed, but migration is still running in post-copy mode
      ]

      # enum virDomainEventStoppedDetailType
      enum :event_stopped_detail_type, [
          :SHUTDOWN, 0x0, # Normal shutdown
          :DESTROYED, 0x1, # Forced poweroff from host
          :CRASHED, 0x2, # Guest crashed
          :MIGRATED, 0x3, # Migrated off to another host
          :SAVED, 0x4, # Saved to a state file
          :FAILED, 0x5, # Host emulator/mgmt failed
          :FROM_SNAPSHOT, 0x6 # offline snapshot loaded
      ]

      # enum virDomainEventShutdownDetailType
      enum :event_shutdown_detail_type, [
          :FINISHED, 0x0, # Guest finished shutdown sequence
          :GUEST, 0x1, # Domain finished shutting down after request from the guest itself (e.g. hardware-specific action)
          :HOST, 0x2 # Domain finished shutting down after request from the host (e.g. killed by a signal)
      ]

      # enum virDomainEventPMSuspendedDetailType
      enum :event_pmsuspended_detail_type, [
          :MEMORY, 0x0, # Guest was PM suspended to memory
          :DISK, 0x1 # Guest was PM suspended to disk
      ]

      # enum virDomainEventCrashedDetailType
      enum :event_crashed_detail_type, [
          :PANICKED, 0x0 # Guest was panicked
      ]

      # enum virDomainSaveRestoreFlags
      enum :save_restore_flags, [
          :BYPASS_CACHE, 0x1, # Avoid file system cache pollution
          :RUNNING, 0x2, # Favor running over paused
          :PAUSED, 0x4 # Favor paused over running
      ]

      # enum virDomainShutdownFlagValues
      enum :shutdown_flags, [
          :DEFAULT, 0x0, # hypervisor choice
          :ACPI_POWER_BTN, 0x1, # Send ACPI event
          :GUEST_AGENT, 0x2, # Use guest agent
          :INITCTL, 0x4, # Use initctl
          :SIGNAL, 0x8, # Send a signal
          :PARAVIRT, 0x10 # Use paravirt guest control
      ]

      # enum virDomainUndefineFlagsValues
      enum :undefine_flags_values, [
          :MANAGED_SAVE, 0x1, # Also remove any managed save
          :SNAPSHOTS_METADATA, 0x2, # If last use of domain, then also remove any snapshot metadata
          :NVRAM, 0x4, # Also remove any nvram file
          :KEEP_NVRAM, 0x8, # Keep nvram file
          :CHECKPOINTS_METADATA, 0x10 # If last use of domain, then also remove any checkpoint metadata Future undefine control flags should come here.
      ]

      # enum virDomainDefineFlags
      enum :define_flags, [
          :DEFINE_VALIDATE, 0x1 # Validate the XML document against schema
      ]

      # enum virDomainMetadataType
      enum :metadata_type, [
          :DESCRIPTION, 0x0, # Operate on <description>
          :TITLE, 0x1, # Operate on <title>
          :ELEMENT, 0x2 # Operate on <metadata>
      ]

      # enum virDomainModificationImpact
      enum :modification_impact, [
          :AFFECT_CURRENT, 0x0, # Affect current domain state.
          :AFFECT_LIVE, 0x1, # Affect running domain state.
          :AFFECT_CONFIG, 0x2 # Affect persistent domain state. 1 << 2 is reserved for virTypedParameterFlags
      ]

      # enum virDomainXMLFlags
      enum :xml_flags, [
          :SECURE, 0x1, # dump security sensitive information too
          :INACTIVE, 0x2, # dump inactive domain information
          :UPDATE_CPU, 0x4, # update guest CPU requirements according to host CPU
          :MIGRATABLE, 0x8 # dump XML suitable for migration
      ]

      # int virDomainFree (
      #   virDomainPtr domain
      # )
      attach_function :virDomainFree, [:pointer], :int

      # int virDomainRef (
      #   virDomainPtr domain
      # )
      attach_function :virDomainRef, [:pointer], :int

      # int virConnectDomainEventRegisterAny(
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int eventID,
      #   virConnectDomainEventGenericCallback cb,
      #   void * opaque,
      #   virFreeCallback freecb
      # )
      attach_function :virConnectDomainEventRegisterAny, [
          :pointer,
          :pointer,
          :int,
          :pointer,
          :pointer,
          :pointer
      ], :int

      # int virConnectDomainEventDeregisterAny (
      #   virConnectPtr conn,
      #   int callbackID
      # )
      attach_function :virConnectDomainEventDeregisterAny, [:pointer, :int], :int

      # int virConnectListAllDomains (
      #   virConnectPtr conn,
      #   virDomainPtr **domains,
      #   unsigned int flags
      # )
      attach_function :virConnectListAllDomains, [:pointer, :pointer, :uint], :int

      # int virDomainGetState (
      #   virDomainPtr domain,
      #   int *state,
      #   int *reason,
      #   unsigned int flags
      # )
      attach_function :virDomainGetState, [:pointer, :pointer, :pointer, :uint], :int

      # const char *virDomainGetName (
      #   virDomainPtr domain
      # )
      attach_function :virDomainGetName, [:pointer], :string

      # int virDomainGetMaxVcpus (
      #   virDomainPtr domain
      # )
      attach_function :virDomainGetMaxVcpus, [:pointer], :int

      # int virDomainGetVcpus (
      #   virDomainPtr domain,
      #   virVcpuInfoPtr info,
      #   int maxinfo,
      #   unsigned char * cpumaps,
      #   int maplen
      # )
      attach_function :virDomainGetVcpus, [:pointer, :pointer, :int, :pointer, :int], :int

      # int virDomainGetUUIDString (
      #   virDomainPtr domain,
      #   char * buf
      # )
      attach_function :virDomainGetUUIDString, [:pointer, :pointer], :int

      # unsigned long  virDomainGetMaxMemory (
      #   virDomainPtr domain
      # )
      attach_function :virDomainGetMaxMemory, [:pointer], :ulong

      # char *virDomainGetXMLDesc (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainGetXMLDesc, [:pointer, :xml_flags], :string

      # char *virDomainScreenshot (
      #   virDomainPtr domain,
      #   virStreamPtr stream,
      #   unsigned int screen,
      #   unsigned int flags
      # )
      attach_function :virDomainScreenshot, [:pointer, :pointer, :uint, :uint], :strptr

      # typedef int (*virConnectDomainEventCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int event,
      #   int detail,
      #   void * opaque
      # )
      callback :virConnectDomainEventCallback, [:pointer, :pointer, :event_type, :int, :pointer], :int

      # typedef void (*virConnectDomainEventGenericCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   void * opaque
      # )
      callback :virConnectDomainEventGenericCallback, [:pointer, :pointer, :pointer], :void

      # typedef void (*virConnectDomainEventRTCChangeCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   long long utcoffset,
      #   void * opaque
      # )
      callback :virConnectDomainEventRTCChangeCallback, [
          :pointer,
          :pointer,
          :long_long,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventWatchdogCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int action,
      #   void * opaque
      # )
      callback :virConnectDomainEventWatchdogCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventIOErrorCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * srcPath,
      #   const char * devAlias,
      #   int action,
      #   void * opaque
      # )
      callback :virConnectDomainEventIOErrorCallback, [
          :pointer,
          :pointer,
          :string,
          :string,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventGraphicsCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int phase,
      #   const virDomainEventGraphicsAddress * local,
      #   const virDomainEventGraphicsAddress * remote,
      #   const char * authScheme,
      #   const virDomainEventGraphicsSubject * subject,
      #   void * opaque
      # )
      callback :virConnectDomainEventGraphicsCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer,
          :pointer,
          :string,
          :pointer,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventIOErrorReasonCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * srcPath,
      #   const char * devAlias,
      #   int action,
      #   const char * reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventIOErrorReasonCallback, [
          :pointer,
          :pointer,
          :string,
          :string,
          :int,
          :string,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventBlockJobCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * disk,
      #   int type,
      #   int status,
      #   void * opaque
      # )
      callback :virConnectDomainEventBlockJobCallback, [
          :pointer,
          :pointer,
          :string,
          :int,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventDiskChangeCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * oldSrcPath,
      #   const char * newSrcPath,
      #   const char * devAlias,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventDiskChangeCallback, [
          :pointer,
          :pointer,
          :string,
          :string,
          :string,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventTrayChangeCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * devAlias,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventTrayChangeCallback, [
          :pointer,
          :pointer,
          :string,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventPMWakeupCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventPMWakeupCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventPMSuspendCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventPMSuspendCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventBalloonChangeCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   unsigned long long actual,
      #   void * opaque
      # )
      callback :virConnectDomainEventBalloonChangeCallback, [
          :pointer,
          :pointer,
          :ulong_long,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventPMSuspendDiskCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventPMSuspendDiskCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventDeviceRemovedCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * devAlias,
      #   void * opaque
      # )
      callback :virConnectDomainEventDeviceRemovedCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventTunableCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   virTypedParameterPtr params,
      #   int nparams,
      #   void * opaque
      # )
      callback :virConnectDomainEventTunableCallback, [
          :pointer,
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventAgentLifecycleCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int state,
      #   int reason,
      #   void * opaque
      # )
      callback :virConnectDomainEventAgentLifecycleCallback, [
          :pointer,
          :pointer,
          :int,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventDeviceAddedCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * devAlias,
      #   void * opaque
      # )
      callback :virConnectDomainEventDeviceAddedCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventMigrationIterationCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int iteration,
      #   void * opaque
      # )
      callback :virConnectDomainEventMigrationIterationCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventJobCompletedCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   virTypedParameterPtr params,
      #   int nparams,
      #   void * opaque
      # )
      callback :virConnectDomainEventJobCompletedCallback, [
          :pointer,
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventDeviceRemovalFailedCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * devAlias,
      #   void * opaque
      # )
      callback :virConnectDomainEventDeviceRemovalFailedCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventMetadataChangeCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   int type,
      #   const char * nsuri,
      #   void * opaque
      # )
      callback :virConnectDomainEventMetadataChangeCallback, [
          :pointer,
          :pointer,
          :metadata_type,
          :string,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventBlockThresholdCallback) (
      #   virConnectPtr conn,
      #   virDomainPtr dom,
      #   const char * dev,
      #   const char * path,
      #   unsigned long long threshold,
      #   unsigned long long excess,
      #   void * opaque
      # )
      callback :virConnectDomainEventBlockThresholdCallback, [
          :pointer,
          :pointer,
          :string,
          :string,
          :ulong_long,
          :ulong_long,
          :pointer
      ], :void

      # int virDomainReboot (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainReboot, [:pointer, :uint], :int

      # int virDomainShutdownFlags (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainShutdownFlags, [:pointer, :shutdown_flags], :int

      # int virDomainDestroyFlags (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainDestroyFlags, [:pointer, :uint], :int

      # int virDomainReset (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainReset, [:pointer, :uint], :int

      # int virDomainSuspend (
      #   virDomainPtr domain
      # )
      attach_function :virDomainSuspend, [:pointer], :int

      # int virDomainResume (
      #   virDomainPtr domain
      # )
      attach_function :virDomainResume, [:pointer], :int

      # int virDomainCreateWithFlags (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainCreateWithFlags, [:pointer, :uint], :int

      # int virDomainManagedSave (
      #   virDomainPtr dom,
      #   unsigned int flags
      # )
      attach_function :virDomainManagedSave, [:pointer, :save_restore_flags], :int

      # int virDomainUndefineFlags (
      #   virDomainPtr domain,
      #   unsigned int flags
      # )
      attach_function :virDomainUndefineFlags, [:pointer, :uint], :int

      # virDomainPtr virDomainDefineXMLFlags (
      #   virConnectPtr conn,
      #   const char * xml,
      #   unsigned int flags
      # )
      attach_function :virDomainDefineXMLFlags, [:pointer, :string, :uint], :pointer

      # int virDomainSetMetadata (
      #   virDomainPtr domain,
      #   int type,
      #   const char * metadata,
      #   const char * key,
      #   const char * uri,
      #   unsigned int flags
      # )
      attach_function :virDomainSetMetadata,
                      [:pointer, :metadata_type, :string, :string, :string, :modification_impact],
                      :int

      # char * virDomainGetMetadata (
      #   virDomainPtr domain,
      #   int type,
      #   const char * uri,
      #   unsigned int flags
      # )
      attach_function :virDomainGetMetadata,
                      [:pointer, :metadata_type, :string, :modification_impact],
                      :string

      # int virDomainIsPersistent (
      #   virDomainPtr dom
      # )
      attach_function :virDomainIsPersistent, [:pointer], :int

      # int virDomainGetAutostart (
      #   virDomainPtr domain,
      #   int * autostart
      # )
      attach_function :virDomainGetAutostart, [:pointer, :pointer], :int

      # int virDomainSetAutostart (
      #   virDomainPtr domain,
      #   int autostart
      # )
      attach_function :virDomainSetAutostart, [:pointer, :int], :int

      # Converts detail from lifecycle callback from integer to symbol name.
      # @param event [Symbol] enum :event_type (virDomainEventType)
      # @param detail [Integer]
      # @return [Symbol]
      def self.event_detail_type(event, detail)
        detail_enum = enum_type(:"event_#{event.to_s.downcase}_detail_type")
        detail_enum[detail]
      end

      # Converts state reason of domain from integer to symbol name.
      # @param state [Symbol] enum :state (virDomainState)
      # @param reason [Integer]
      # @return [Symbol]
      def self.state_reason(state, reason)
        reason_enum = enum_type(:"#{state.to_s.downcase}_reason")
        reason_enum[reason]
      end

      # Creates event callback function for provided event_id
      # @param event_id [Integer,Symbol]
      # @yield connect_ptr, domain_ptr, *args, opaque_ptr
      # @return [FFI::Function]
      def self.event_callback_for(event_id, &block)
        event_id_sym = event_id.is_a?(Symbol) ? event_id : enum_type(:event_id)[event_id]

        case event_id_sym
        when :LIFECYCLE
          event_callback(&block)
        else
          event_callback_base(event_id_sym, &block)
        end
      end

      # Creates generic event callback function for provided event_id_sym
      # @param event_id_sym [Symbol]
      # @yield connect_ptr, domain_ptr, *args, opaque_ptr
      # @return [FFI::Function]
      def self.event_callback_base(event_id_sym, &block)
        callback_name = EVENT_ID_TO_CALLBACK.fetch(event_id_sym)
        callback_function(callback_name) do |*args|
          Util.log(:debug) { "Libvirt::Domain #{event_id_sym} CALLBACK #{args.map(&:to_s).join(', ')}," }
          block.call(*args)
        end
      end

      # Creates event callback function for lifecycle event_id
      # @param event_id_sym [Symbol]
      # @yield connect_ptr, domain_ptr, event, detail, opaque_ptr
      # @return [FFI::Function]
      def self.event_callback(&block)
        callback_function(:virConnectDomainEventCallback) do |conn, dom, event, detail, opaque|
          detail_sym = event_detail_type(event, detail)
          Util.log(:debug) { "Libvirt::Domain LIFECYCLE CALLBACK #{conn}, #{dom}, #{event}, #{detail_sym}, #{opaque}," }
          block.call(conn, dom, event, detail_sym, opaque)
          0
        end
      end
    end
  end
end
