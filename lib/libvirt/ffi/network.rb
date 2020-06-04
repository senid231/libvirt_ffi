# frozen_string_literal: true

module Libvirt
  module FFI
    module Network
      # https://libvirt.org/html/libvirt-libvirt-network.html

      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      EVENT_ID_TO_CALLBACK = {
          LIFECYCLE: :virConnectNetworkEventLifecycleCallback
      }.freeze

      ## Enums

      # enum virConnectListAllNetworksFlags
      enum :list_all_flags, [
          :INACTIVE, 0x1,
          :ACTIVE, 0x2,
          :PERSISTENT, 0x4,
          :TRANSIENT, 0x8,
          :AUTOSTART, 0x10,
          :NO_AUTOSTART, 0x20
      ]

      # enum virIPAddrType
      enum :ip_addr_type, [
          :IPV4, 0x0,
          :IPV6, 0x1
      ]

      # enum virNetworkEventID
      enum :event_id, [
          :LIFECYCLE, 0x0 # virConnectNetworkEventLifecycleCallback
      ]

      # enum virNetworkEventLifecycleType
      enum :event_lifecycle_type, [
          :DEFINED, 0x0,
          :UNDEFINED, 0x1,
          :STARTED, 0x2,
          :STOPPED, 0x3
      ]

      # enum virNetworkUpdateCommand
      enum :update_command, [
          :NONE, 0x0, # (invalid)
          :MODIFY, 0x1, # modify an existing element
          :DELETE, 0x2, # delete an existing element
          :ADD_LAST, 0x3, # add an element at end of list
          :ADD_FIRST, 0x4 # add an element at start of list
      ]

      # enum virNetworkUpdateFlags
      enum :update_flags, [
          :AFFECT_CURRENT, 0x0, # affect live if network is active, config if its not active
          :AFFECT_LIVE, 0x1, # affect live state of network only
          :AFFECT_CONFIG, 0x2 # affect persistent config only
      ]

      # enum virNetworkUpdateSection
      enum :update_section, [
          :NONE, 0x0, # (invalid)
          :BRIDGE, 0x1, # <bridge>
          :DOMAIN, 0x2, # <domain>
          :IP, 0x3, # <ip>
          :IP_DHCP_HOST, 0x4, # <ip>/<dhcp>/<host>
          :IP_DHCP_RANGE, 0x5, # <ip>/<dhcp>/<range>
          :FORWARD, 0x6, # <forward>
          :FORWARD_INTERFACE, 0x7, # <forward>/<interface>
          :FORWARD_PF, 0x8, # <forward>/<pf>
          :PORTGROUP, 0x9, # <portgroup>
          :DNS_HOST, 0xa, # <dns>/<host>
          :DNS_TXT, 0xb, # <dns>/<txt>
          :DNS_SRV, 0xc # <dns>/<srv>
      ]

      # enum virNetworkXMLFlags
      enum :xml_flags, [
          :INACTIVE, 0x1 # dump inactive network information
      ]

      ## Structs

      # struct virNetworkDHCPLease {
      #   char *   iface # Network interface name
      #   long long   expirytime # Seconds since epoch
      #   int   type # virIPAddrType
      #   char *   mac # MAC address
      #   char *   iaid # IAID
      #   char *   ipaddr # IP address
      #   unsigned int   prefix # IP address prefix
      #   char *   hostname # Hostname
      #   char *   clientid # Client ID or DUID
      # }
      class DhcpLeaseStruct < ::FFI::Struct
        layout :iface, :string,
               :expirytime, :long_long,
               :type, FFI::Network.enum_type(:ip_addr_type),
               :mac, :string,
               :iaid, :string,
               :ipaddr, :string,
               :prefix, :uint,
               :hostname, :string,
               :clientid, :string
      end

      ## Callbacks

      # typedef virConnectNetworkEventGenericCallback
      # void  virConnectNetworkEventGenericCallback  (
      #   virConnectPtr conn,
      #   virNetworkPtr net,
      #   void * opaque
      # )
      callback :virConnectNetworkEventGenericCallback,
               [:pointer, :pointer, :pointer],
               :void

      # typedef virConnectNetworkEventLifecycleCallback
      # void  virConnectNetworkEventLifecycleCallback  (
      #   virConnectPtr conn,
      #   virNetworkPtr net,
      #   int event,
      #   int detail,
      #   void * opaque
      # )
      callback :virConnectNetworkEventLifecycleCallback,
               [:pointer, :pointer, :event_lifecycle_type, :int, :pointer],
               :void

      ## Functions

      # int  virConnectListAllNetworks  (
      #   virConnectPtr conn,
      #   virNetworkPtr ** nets,
      #   unsigned int flags
      # )
      attach_function :virConnectListAllNetworks,
                      [:pointer, :pointer, :list_all_flags],
                      :int

      # int  virConnectListDefinedNetworks  (
      #   virConnectPtr conn,
      #   char ** const names,
      #   int maxnames
      # )
      attach_function :virConnectListDefinedNetworks,
                      [:pointer, :pointer, :int],
                      :int

      # int  virConnectListNetworks (
      #   virConnectPtr conn,
      #   char ** const names,
      #   int maxnames
      # )
      attach_function :virConnectListNetworks,
                      [:pointer, :pointer, :int],
                      :int

      # int  virConnectNetworkEventDeregisterAny  (
      #   virConnectPtr conn,
      #   int callbackID
      # )
      attach_function :virConnectNetworkEventDeregisterAny, [:pointer, :int], :int

      # int  virConnectNetworkEventRegisterAny  (
      #   virConnectPtr conn,
      #   virNetworkPtr net,
      #   int eventID,
      #   virConnectNetworkEventGenericCallback cb,
      #   void * opaque,
      #   virFreeCallback freecb
      # )
      attach_function :virConnectNetworkEventRegisterAny,
                      [:pointer, :pointer, :event_id, :pointer, :pointer, :pointer],
                      :int

      # int  virConnectNumOfDefinedNetworks (
      #   virConnectPtr conn
      # )
      attach_function :virConnectNumOfDefinedNetworks,
                      [:pointer],
                      :int

      # int  virConnectNumOfNetworks (
      #   virConnectPtr conn
      # )
      attach_function :virConnectNumOfNetworks,
                      [:pointer],
                      :int

      # int  virNetworkCreate (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkCreate,
                      [:pointer],
                      :int

      # virNetworkPtr  virNetworkCreateXML  (
      #   virConnectPtr conn,
      #   const char * xmlDesc
      # )
      attach_function :virNetworkCreateXML,
                      [:pointer, :string],
                      :pointer

      # void  virNetworkDHCPLeaseFree (
      #   virNetworkDHCPLeasePtr lease
      # )
      attach_function :virNetworkDHCPLeaseFree,
                      [:pointer],
                      :void

      # virNetworkPtr  virNetworkDefineXML  (
      #   virConnectPtr conn,
      #   const char * xml
      # )
      attach_function :virNetworkDefineXML,
                      [:pointer, :string],
                      :pointer

      # int  virNetworkDestroy (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkDestroy,
                      [:pointer],
                      :int

      # int  virNetworkFree (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkFree,
                      [:pointer],
                      :int

      # int  virNetworkGetAutostart (
      #   virNetworkPtr network,
      #   int * autostart
      # )
      attach_function :virNetworkGetAutostart,
                      [:pointer, :pointer],
                      :int

      # char * virNetworkGetBridgeName (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkGetBridgeName,
                      [:pointer],
                      :string

      # virConnectPtr  virNetworkGetConnect (
      #   virNetworkPtr net
      # )
      attach_function :virNetworkGetConnect,
                      [:pointer],
                      :pointer

      # int  virNetworkGetDHCPLeases (
      #   virNetworkPtr network,
      #   const char * mac,
      #   virNetworkDHCPLeasePtr ** leases,
      #   unsigned int flags
      # )
      attach_function :virNetworkGetDHCPLeases,
                      [:pointer, :string, :pointer, :uint],
                      :int

      # const char * virNetworkGetName (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkGetName,
                      [:pointer],
                      :string

      # int  virNetworkGetUUID  (
      #   virNetworkPtr network,
      #   unsigned char * uuid
      # )
      attach_function :virNetworkGetUUID,
                      [:pointer, :pointer],
                      :int

      # int  virNetworkGetUUIDString (
      #   virNetworkPtr network,
      #   char * buf
      # )
      attach_function :virNetworkGetUUIDString,
                      [:pointer, :pointer],
                      :int

      # char *  virNetworkGetXMLDesc (
      #   virNetworkPtr network,
      #   unsigned int flags
      # )
      attach_function :virNetworkGetXMLDesc,
                      [:pointer, :xml_flags],
                      :string

      # int  virNetworkIsActive (
      #   virNetworkPtr net
      # )
      attach_function :virNetworkIsActive,
                      [:pointer],
                      :int

      # int  virNetworkIsPersistent (
      #   virNetworkPtr net
      # )
      attach_function :virNetworkIsPersistent,
                      [:pointer],
                      :int

      # virNetworkPtr  virNetworkLookupByName (
      #   virConnectPtr conn,
      #   const char * name
      # )
      attach_function :virNetworkLookupByName,
                      [:pointer, :string],
                      :pointer

      # virNetworkPtr  virNetworkLookupByUUID (
      #   virConnectPtr conn,
      #   const unsigned char * uuid
      # )
      attach_function :virNetworkLookupByUUID,
                      [:pointer, :pointer],
                      :pointer

      # virNetworkPtr  virNetworkLookupByUUIDString (
      #   virConnectPtr conn,
      #   const char * uuidstr
      # )
      attach_function :virNetworkLookupByUUIDString,
                      [:pointer, :string],
                      :pointer

      # int  virNetworkRef (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkRef,
                      [:pointer],
                      :int

      # int  virNetworkSetAutostart (
      #   virNetworkPtr network,
      #   int autostart
      # )
      attach_function :virNetworkSetAutostart,
                      [:pointer, :int],
                      :int

      # int  virNetworkUndefine (
      #   virNetworkPtr network
      # )
      attach_function :virNetworkUndefine,
                      [:pointer],
                      :int

      # int  virNetworkUpdate (
      #   virNetworkPtr network,
      #   unsigned int command,
      #   unsigned int section,
      #   int parentIndex,
      #   const char * xml,
      #   unsigned int flags
      # )
      attach_function :virNetworkUpdate,
                      [:pointer, :update_command, :update_section, :int, :string, :update_flags],
                      :int

      ## Helpers
      module_function

      # Creates event callback function for provided event_id
      # @param event_id [Integer,Symbol]
      # @yield connect_ptr, network_ptr, *args, opaque_ptr
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
