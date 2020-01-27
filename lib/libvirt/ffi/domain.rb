# frozen_string_literal: true

require 'ffi'
require 'libvirt/util'
require 'libvirt/ffi/common'

module Libvirt
  module FFI
    module Domain
      extend ::FFI::Library
      ffi_lib Util.library_path

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
