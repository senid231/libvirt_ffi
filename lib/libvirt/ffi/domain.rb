# frozen_string_literal: true

module Libvirt
  module FFI
    module Domain
      extend ::FFI::Library
      ffi_lib Util.library_path

      UUID_STRING_BUFLEN = 0x80 # RFC4122

      # enum virDomainEventID
      enum :event_id, [
          :LIFECYCLE, 0,              # (0x0) virConnectDomainEventCallback
          :REBOOT, 1,                 # (0x1) virConnectDomainEventGenericCallback
          :RTC_CHANGE, 2,             # (0x2) virConnectDomainEventRTCChangeCallback
          :WATCHDOG, 3,               # (0x3) virConnectDomainEventWatchdogCallback
          :IO_ERROR, 4,               # (0x4) virConnectDomainEventIOErrorCallback
          :GRAPHICS, 5,               # (0x5) virConnectDomainEventGraphicsCallback
          :IO_ERROR_REASON, 6,        # (0x6) virConnectDomainEventIOErrorReasonCallback
          :CONTROL_ERROR, 7,          # (0x7) virConnectDomainEventGenericCallback
          :BLOCK_JOB, 8,              # (0x8) virConnectDomainEventBlockJobCallback
          :DISK_CHANGE, 9,            # (0x9) virConnectDomainEventDiskChangeCallback
          :TRAY_CHANGE, 10,           # (0xa) virConnectDomainEventTrayChangeCallback
          :PMWAKEUP, 11,              # (0xb) virConnectDomainEventPMWakeupCallback
          :PMSUSPEND, 12,             # (0xc) virConnectDomainEventPMSuspendCallback
          :BALLOON_CHANGE, 13,        # (0xd) virConnectDomainEventBalloonChangeCallback
          :PMSUSPEND_DISK, 14,        # (0xe) virConnectDomainEventPMSuspendDiskCallback
          :DEVICE_REMOVED, 15,        # (0xf) virConnectDomainEventDeviceRemovedCallback
          :BLOCK_JOB_2, 16,           # (0x10) virConnectDomainEventBlockJobCallback
          :TUNABLE, 17,               # (0x11) virConnectDomainEventTunableCallback
          :AGENT_LIFECYCLE, 18,       # (0x12) virConnectDomainEventAgentLifecycleCallback
          :DEVICE_ADDED, 19,          # (0x13) virConnectDomainEventDeviceAddedCallback
          :MIGRATION_ITERATION, 20,   # (0x14) virConnectDomainEventMigrationIterationCallback
          :JOB_COMPLETED, 21,         # (0x15) virConnectDomainEventJobCompletedCallback
          :DEVICE_REMOVAL_FAILED, 22, # (0x16) virConnectDomainEventDeviceRemovalFailedCallback
          :METADATA_CHANGE, 23,       # (0x17) virConnectDomainEventMetadataChangeCallback
          :BLOCK_THRESHOLD, 24        # (0x18) virConnectDomainEventBlockThresholdCallback
      ]

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
      }

      # enum virDomainState
      enum :state, [
          :NOSTATE, 0x0,    # no state
          :RUNNING, 0x1,    # the domain is running
          :BLOCKED, 0x2,    # the domain is blocked on resource
          :PAUSED, 0x3,     # the domain is paused by user
          :SHUTDOWN, 0x4,   # the domain is being shut down
          :SHUTOFF, 0x5,    # the domain is shut off
          :CRASHED, 0x6,    # the domain is crashed
          :PMSUSPENDED, 0x7 # the domain is suspended by guest power management
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

      # int	virDomainFree	(
      #   virDomainPtr domain
      # )
      attach_function :virDomainFree, [:pointer], :int

      # int	virDomainRef (
      #   virDomainPtr domain
      # )
      attach_function :virDomainRef, [:pointer], :int

      # int	virConnectDomainEventRegisterAny(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int eventID,
      # 	virConnectDomainEventGenericCallback cb,
      # 	void * opaque,
      # 	virFreeCallback freecb
      # )
      attach_function :virConnectDomainEventRegisterAny, [
          :pointer,
          :pointer,
          :int,
          :pointer,
          :pointer,
          :pointer
      ], :int

      # int	virConnectDomainEventDeregisterAny (
      #   virConnectPtr conn,
      # 	int callbackID
      # )
      attach_function :virConnectDomainEventDeregisterAny, [:pointer, :int], :int

      # int	virConnectListAllDomains (
      #   virConnectPtr conn,
      # 	virDomainPtr **domains,
      # 	unsigned int flags
      # )
      attach_function :virConnectListAllDomains, [:pointer, :pointer, :uint], :int

      # int	virDomainGetState	(
      #   virDomainPtr domain,
      # 	int *state,
      # 	int *reason,
      # 	unsigned int flags
      # )
      attach_function :virDomainGetState, [:pointer, :pointer, :pointer, :uint], :int

      # const char *virDomainGetName (
      #   virDomainPtr domain
      # )
      attach_function :virDomainGetName, [:pointer], :string # strptr?

      # int	virDomainGetMaxVcpus (
      #   virDomainPtr domain
      # )
      attach_function :virDomainGetMaxVcpus, [:pointer], :int

      # int	virDomainGetVcpus	(
      #   virDomainPtr domain,
      # 	virVcpuInfoPtr info,
      # 	int maxinfo,
      # 	unsigned char * cpumaps,
      # 	int maplen
      # )
      attach_function :virDomainGetVcpus, [:pointer, :pointer, :int, :pointer, :int], :int

      # int	virDomainGetUUIDString (
      #   virDomainPtr domain,
      # 	char * buf
      # )
      attach_function :virDomainGetUUIDString, [:pointer, :pointer], :int

      # unsigned long	virDomainGetMaxMemory	(
      #   virDomainPtr domain
      # )
      attach_function :virDomainGetMaxMemory, [:pointer], :ulong

      # char *virDomainGetXMLDesc	(
      #   virDomainPtr domain,
      # 	unsigned int flags
      # )
      attach_function :virDomainGetXMLDesc, [:pointer, :uint], :string # strptr?

      # char *virDomainScreenshot (
      #   virDomainPtr domain,
      # 	virStreamPtr stream,
      # 	unsigned int screen,
      # 	unsigned int flags
      # )
      attach_function :virDomainScreenshot, [:pointer, :pointer, :uint, :uint], :strptr

      # typedef int	(*virConnectDomainEventCallback) (
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int event,
      # 	int detail,
      # 	void * opaque
      # )
      callback :virConnectDomainEventCallback, [:pointer, :pointer, :event_type, :int, :pointer], :int

      # typedef void (*virConnectDomainEventGenericCallback) (
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	void * opaque
      # )
      callback :virConnectDomainEventGenericCallback, [:pointer, :pointer, :pointer], :void

      # typedef void (*virConnectDomainEventRTCChangeCallback) (
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	long long utcoffset,
      # 	void * opaque
      # )
      callback :virConnectDomainEventRTCChangeCallback, [
          :pointer,
          :pointer,
          :long_long,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventWatchdogCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int action,
      # 	void * opaque
      # )
      callback :virConnectDomainEventWatchdogCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventIOErrorCallback) (
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * srcPath,
      # 	const char * devAlias,
      # 	int action,
      # 	void * opaque
      # )
      callback :virConnectDomainEventIOErrorCallback, [
          :pointer,
          :pointer,
          :string,
          :string,
          :int,
          :pointer
      ], :void

      # typedef void (*virConnectDomainEventGraphicsCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int phase,
      # 	const virDomainEventGraphicsAddress * local,
      # 	const virDomainEventGraphicsAddress * remote,
      # 	const char * authScheme,
      # 	const virDomainEventGraphicsSubject * subject,
      # 	void * opaque
      # )
      callback :virConnectDomainEventGraphicsCallback, [
          :pointer,
          :pointer,
          :int,
          # virDomainEventGraphicsAddress
          # virDomainEventGraphicsAddress
          :string,
          # virDomainEventGraphicsSubject
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventIOErrorReasonCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * srcPath,
      # 	const char * devAlias,
      # 	int action,
      # 	const char * reason,
      # 	void * opaque
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

      # typedef void	(*virConnectDomainEventBlockJobCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * disk,
      # 	int type,
      # 	int status,
      # 	void * opaque
      # )
      callback :virConnectDomainEventBlockJobCallback, [
          :pointer,
          :pointer,
          :string,
          :int,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventDiskChangeCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * oldSrcPath,
      # 	const char * newSrcPath,
      # 	const char * devAlias,
      # 	int reason,
      # 	void * opaque
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

      # typedef void	(*virConnectDomainEventTrayChangeCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * devAlias,
      # 	int reason,
      # 	void * opaque
      # )
      callback :virConnectDomainEventTrayChangeCallback, [
          :pointer,
          :pointer,
          :string,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventPMWakeupCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int reason,
      # 	void * opaque
      # )
      callback :virConnectDomainEventPMWakeupCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventPMSuspendCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int reason,
      # 	void * opaque
      # )
      callback :virConnectDomainEventPMSuspendCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventBalloonChangeCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	unsigned long long actual,
      # 	void * opaque
      # )
      callback :virConnectDomainEventBalloonChangeCallback, [
          :pointer,
          :pointer,
          :ulong_long,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventPMSuspendDiskCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int reason,
      # 	void * opaque
      # )
      callback :virConnectDomainEventPMSuspendDiskCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventDeviceRemovedCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * devAlias,
      # 	void * opaque
      # )
      callback :virConnectDomainEventDeviceRemovedCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventTunableCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	virTypedParameterPtr params,
      # 	int nparams,
      # 	void * opaque
      # )
      callback :virConnectDomainEventTunableCallback, [
          :pointer,
          :pointer,
          # virTypedParameterPtr
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventAgentLifecycleCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int state,
      # 	int reason,
      # 	void * opaque
      # )
      callback :virConnectDomainEventAgentLifecycleCallback, [
          :pointer,
          :pointer,
          :int,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventDeviceAddedCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * devAlias,
      # 	void * opaque
      # )
      callback :virConnectDomainEventDeviceAddedCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventMigrationIterationCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int iteration,
      # 	void * opaque
      # )
      callback :virConnectDomainEventMigrationIterationCallback, [
          :pointer,
          :pointer,
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventJobCompletedCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	virTypedParameterPtr params,
      # 	int nparams,
      # 	void * opaque
      # )
      callback :virConnectDomainEventJobCompletedCallback, [
          :pointer,
          :pointer,
          # virTypedParameterPtr
          :int,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventDeviceRemovalFailedCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * devAlias,
      # 	void * opaque
      # )
      callback :virConnectDomainEventDeviceRemovalFailedCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventMetadataChangeCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	int type,
      # 	const char * nsuri,
      # 	void * opaque
      # )
      callback :virConnectDomainEventMetadataChangeCallback, [
          :pointer,
          :pointer,
          :string,
          :pointer
      ], :void

      # typedef void	(*virConnectDomainEventBlockThresholdCallback)	(
      #   virConnectPtr conn,
      # 	virDomainPtr dom,
      # 	const char * dev,
      # 	const char * path,
      # 	unsigned long long threshold,
      # 	unsigned long long excess,
      # 	void * opaque
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

      # @param event_id [Integer]
      # @yield connect_ptr, domain_ptr, *args, opaque_ptr
      def self.event_callback(event_id, &block)
        event_id_sym = enum_type(:event_id)[event_id]
        callback_name = EVENT_ID_TO_CALLBACK.fetch(event_id_sym)
        callback_info = find_type(callback_name)
        ::FFI::Function.new(callback_info.result_type, callback_info.param_types) do |*args|
          Util.log(:debug) { "Libvirt::Domain #{event_id_sym} CALLBACK #{args.map(&:to_s).join(', ')}," }
          block.call(*args)
          # Only callback for lifecycle must return 0.
          # Return value of other callbacks are ignored.
          # So we just pass zero everywhere.
          0
        end
      end

    end
  end
end
