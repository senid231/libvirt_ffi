# frozen_string_literal: true

module Libvirt
  module FFI
    module Domain
      extend ::FFI::Library
      ffi_lib Util.library_path

      UUID_STRING_BUFLEN = 0x80 # RFC4122

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

      # int	virConnectListAllDomains (
      #   virConnectPtr conn,
      # 	virDomainPtr **domains,
      # 	unsigned int flags
      # )
      attach_function :virConnectListAllDomains, [:pointer, :pointer, :uint], :int

      # enum virDomainState {
      #   VIR_DOMAIN_NOSTATE 	= 	0 (0x0)
      #   no state
      #   VIR_DOMAIN_RUNNING 	= 	1 (0x1)
      #   the domain is running
      #   VIR_DOMAIN_BLOCKED 	= 	2 (0x2)
      #   the domain is blocked on resource
      #   VIR_DOMAIN_PAUSED 	= 	3 (0x3)
      #   the domain is paused by user
      #   VIR_DOMAIN_SHUTDOWN 	= 	4 (0x4)
      #   the domain is being shut down
      #   VIR_DOMAIN_SHUTOFF 	= 	5 (0x5)
      #   the domain is shut off
      #   VIR_DOMAIN_CRASHED 	= 	6 (0x6)
      #   the domain is crashed
      #   VIR_DOMAIN_PMSUSPENDED 	= 	7 (0x7)
      #   the domain is suspended by guest power management
      #   VIR_DOMAIN_LAST 	= 	8 (0x8)
      # NB: this enum value will increase over time as new events are added to the libvirt API.
      # It reflects the last state supported by this version of the libvirt API.
      # }
      enum :states, [
          :no_state, 0x0,
          :running, 0x1,
          :blocked, 0x2,
          :paused, 0x3,
          :shutdown, 0x4,
          :shutoff, 0x5,
          :crashed, 0x6,
          :pm_suspended, 0x7,
          :last, 0x8
      ]

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
      def self.domain_event_id_lifecycle_callback(&block)
        ::FFI::Function.new(:int, [:pointer, :pointer, :int, :int]) do |_conn, dom, event, detail, op|
          Util.log(:debug) { "DOMAIN_EVENT_CALLBACK LIFECYCLE dom=#{dom}, event=#{event}, detail=#{detail}, op=#{op}" }
          block.call(dom, event, detail, op)
          0
        end
      end

    end
  end
end
