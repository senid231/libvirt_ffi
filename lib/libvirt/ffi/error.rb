# frozen_string_literal: true

module Libvirt
  module FFI
    module Error
      # https://libvirt.org/html/libvirt-virterror.html

      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path


      # enum virErrorDomain
      enum :error_domain, [
          :NONE, 0x0, # None
          :XEN, 0x1, # Error at Xen hypervisor layer
          :XEND, 0x2, # Error at connection with xend daemon
          :XENSTORE, 0x3, # Error at connection with xen store
          :SEXPR, 0x4, # Error in the S-Expression code
          :XML, 0x5, # Error in the XML code
          :DOM, 0x6, # Error when operating on a domain
          :RPC, 0x7, # Error in the XML-RPC code
          :PROXY, 0x8, # Error in the proxy code; unused since 0.8.6
          :CONF, 0x9, # Error in the configuration file handling
          :QEMU, 0xa, # Error at the QEMU daemon
          :NET, 0xb, # Error when operating on a network
          :TEST, 0xc, # Error from test driver
          :REMOTE, 0xd, # Error from remote driver
          :OPENVZ, 0xe, # Error from OpenVZ driver
          :XENXM, 0xf, # Error at Xen XM layer
          :STATS_LINUX, 0x10, # Error in the Linux Stats code
          :LXC, 0x11, # Error from Linux Container driver
          :STORAGE, 0x12, # Error from storage driver
          :NETWORK, 0x13, # Error from network config
          :DOMAIN, 0x14, # Error from domain config
          :UML, 0x15, # Error at the UML driver; unused since 5.0.0
          :NODEDEV, 0x16, # Error from node device monitor
          :XEN_INOTIFY, 0x17, # Error from xen inotify layer
          :SECURITY, 0x18, # Error from security framework
          :VBOX, 0x19, # Error from VirtualBox driver
          :INTERFACE, 0x1a, # Error when operating on an interface
          :ONE, 0x1b, # The OpenNebula driver no longer exists. Retained for ABI/API compat only
          :ESX, 0x1c, # Error from ESX driver
          :PHYP, 0x1d, # Error from the phyp driver, unused since 6.0.0
          :SECRET, 0x1e, # Error from secret storage
          :CPU, 0x1f, # Error from CPU driver
          :XENAPI, 0x20, # Error from XenAPI
          :NWFILTER, 0x21, # Error from network filter driver
          :HOOK, 0x22, # Error from Synchronous hooks
          :DOMAIN_SNAPSHOT, 0x23, # Error from domain snapshot
          :AUDIT, 0x24, # Error from auditing subsystem
          :SYSINFO, 0x25, # Error from sysinfo/SMBIOS
          :STREAMS, 0x26, # Error from I/O streams
          :VMWARE, 0x27, # Error from VMware driver
          :EVENT, 0x28, # Error from event loop impl
          :LIBXL, 0x29, # Error from libxenlight driver
          :LOCKING, 0x2a, # Error from lock manager
          :HYPERV, 0x2b, # Error from Hyper-V driver
          :CAPABILITIES, 0x2c, # Error from capabilities
          :URI, 0x2d, # Error from URI handling
          :AUTH, 0x2e, # Error from auth handling
          :DBUS, 0x2f, # Error from DBus
          :PARALLELS, 0x30, # Error from Parallels
          :DEVICE, 0x31, # Error from Device
          :SSH, 0x32, # Error from libssh2 connection transport
          :LOCKSPACE, 0x33, # Error from lockspace
          :INITCTL, 0x34, # Error from initctl device communication
          :IDENTITY, 0x35, # Error from identity code
          :CGROUP, 0x36, # Error from cgroups
          :ACCESS, 0x37, # Error from access control manager
          :SYSTEMD, 0x38, # Error from systemd code
          :BHYVE, 0x39, # Error from bhyve driver
          :CRYPTO, 0x3a, # Error from crypto code
          :FIREWALL, 0x3b, # Error from firewall
          :POLKIT, 0x3c, # Error from polkit code
          :THREAD, 0x3d, # Error from thread utils
          :ADMIN, 0x3e, # Error from admin backend
          :LOGGING, 0x3f, # Error from log manager
          :XENXL, 0x40, # Error from Xen xl config code
          :PERF, 0x41, # Error from perf
          :LIBSSH, 0x42, # Error from libssh connection transport
          :RESCTRL, 0x43, # Error from resource control
          :FIREWALLD, 0x44, # Error from firewalld
          :DOMAIN_CHECKPOINT, 0x45, # Error from domain checkpoint
          :TPM, 0x46, # Error from TPM
          :BPF, 0x47 # Error from BPF code
      ]

      # enum virErrorLevel
      enum :error_level, [
          :NONE, 0x0, # None
          :WARNING, 0x1, # A simple warning
          :ERROR, 0x2 # An error
      ]


      # enum virErrorNumber
      enum :error_number, [
          :OK, 0x0, # ok
          :INTERNAL_ERROR, 0x1, # internal error
          :NO_MEMORY, 0x2, # memory allocation failure
          :NO_SUPPORT, 0x3, # no support for this function
          :UNKNOWN_HOST, 0x4, # could not resolve hostname
          :NO_CONNECT, 0x5, # can't connect to hypervisor
          :INVALID_CONN, 0x6, # invalid connection object
          :INVALID_DOMAIN, 0x7, # invalid domain object
          :INVALID_ARG, 0x8, # invalid function argument
          :OPERATION_FAILED, 0x9, # a command to hypervisor failed
          :GET_FAILED, 0xa, # a HTTP GET command to failed
          :POST_FAILED, 0xb, # a HTTP POST command to failed
          :HTTP_ERROR, 0xc, # unexpected HTTP error code
          :SEXPR_SERIAL, 0xd, # failure to serialize an S-Expr
          :NO_XEN, 0xe, # could not open Xen hypervisor control
          :XEN_CALL, 0xf, # failure doing an hypervisor call
          :OS_TYPE, 0x10, # unknown OS type
          :NO_KERNEL, 0x11, # missing kernel information
          :NO_ROOT, 0x12, # missing root device information
          :NO_SOURCE, 0x13, # missing source device information
          :NO_TARGET, 0x14, # missing target device information
          :NO_NAME, 0x15, # missing domain name information
          :NO_OS, 0x16, # missing domain OS information
          :NO_DEVICE, 0x17, # missing domain devices information
          :NO_XENSTORE, 0x18, # could not open Xen Store control
          :DRIVER_FULL, 0x19, # too many drivers registered
          :CALL_FAILED, 0x1a, # not supported by the drivers (DEPRECATED)
          :XML_ERROR, 0x1b, # an XML description is not well formed or broken
          :DOM_EXIST, 0x1c, # the domain already exist
          :OPERATION_DENIED, 0x1d, # operation forbidden on read-only connections
          :OPEN_FAILED, 0x1e, # failed to open a conf file
          :READ_FAILED, 0x1f, # failed to read a conf file
          :PARSE_FAILED, 0x20, # failed to parse a conf file
          :CONF_SYNTAX, 0x21, # failed to parse the syntax of a conf file
          :WRITE_FAILED, 0x22, # failed to write a conf file
          :XML_DETAIL, 0x23, # detail of an XML error
          :INVALID_NETWORK, 0x24, # invalid network object
          :NETWORK_EXIST, 0x25, # the network already exist
          :SYSTEM_ERROR, 0x26, # general system call failure
          :RPC, 0x27, # some sort of RPC error
          :GNUTLS_ERROR, 0x28, # error from a GNUTLS call
          :NO_NETWORK_WARN, 0x29, # failed to start network
          :NO_DOMAIN, 0x2a, # domain not found or unexpectedly disappeared
          :NO_NETWORK, 0x2b, # network not found
          :INVALID_MAC, 0x2c, # invalid MAC address
          :AUTH_FAILED, 0x2d, # authentication failed
          :INVALID_STORAGE_POOL, 0x2e, # invalid storage pool object
          :INVALID_STORAGE_VOL, 0x2f, # invalid storage vol object
          :NO_STORAGE_WARN, 0x30, # failed to start storage
          :NO_STORAGE_POOL, 0x31, # storage pool not found
          :NO_STORAGE_VOL, 0x32, # storage volume not found
          :NO_NODE_WARN, 0x33, # failed to start node driver
          :INVALID_NODE_DEVICE, 0x34, # invalid node device object
          :NO_NODE_DEVICE, 0x35, # node device not found
          :NO_SECURITY_MODEL, 0x36, # security model not found
          :OPERATION_INVALID, 0x37, # operation is not applicable at this time
          :NO_INTERFACE_WARN, 0x38, # failed to start interface driver
          :NO_INTERFACE, 0x39, # interface driver not running
          :INVALID_INTERFACE, 0x3a, # invalid interface object
          :MULTIPLE_INTERFACES, 0x3b, # more than one matching interface found
          :NO_NWFILTER_WARN, 0x3c, # failed to start nwfilter driver
          :INVALID_NWFILTER, 0x3d, # invalid nwfilter object
          :NO_NWFILTER, 0x3e, # nw filter pool not found
          :BUILD_FIREWALL, 0x3f, # nw filter pool not found
          :NO_SECRET_WARN, 0x40, # failed to start secret storage
          :INVALID_SECRET, 0x41, # invalid secret
          :NO_SECRET, 0x42, # secret not found
          :CONFIG_UNSUPPORTED, 0x43, # unsupported configuration construct
          :OPERATION_TIMEOUT, 0x44, # timeout occurred during operation
          :MIGRATE_PERSIST_FAILED, 0x45, # a migration worked, but making the VM persist on the dest host failed
          :HOOK_SCRIPT_FAILED, 0x46, # a synchronous hook script failed
          :INVALID_DOMAIN_SNAPSHOT, 0x47, # invalid domain snapshot
          :NO_DOMAIN_SNAPSHOT, 0x48, # domain snapshot not found
          :INVALID_STREAM, 0x49, # stream pointer not valid
          :ARGUMENT_UNSUPPORTED, 0x4a, # valid API use but unsupported by the given driver
          :STORAGE_PROBE_FAILED, 0x4b, # storage pool probe failed
          :STORAGE_POOL_BUILT, 0x4c, # storage pool already built
          :SNAPSHOT_REVERT_RISKY, 0x4d, # force was not requested for a risky domain snapshot revert
          :OPERATION_ABORTED, 0x4e, # operation on a domain was canceled/aborted by user
          :AUTH_CANCELLED, 0x4f, # authentication cancelled
          :NO_DOMAIN_METADATA, 0x50, # The metadata is not present
          :MIGRATE_UNSAFE, 0x51, # Migration is not safe
          :OVERFLOW, 0x52, # integer overflow
          :BLOCK_COPY_ACTIVE, 0x53, # action prevented by block copy job
          :OPERATION_UNSUPPORTED, 0x54, # The requested operation is not supported
          :SSH, 0x55, # error in ssh transport driver
          :AGENT_UNRESPONSIVE, 0x56, # guest agent is unresponsive, not running or not usable
          :RESOURCE_BUSY, 0x57, # resource is already in use
          :ACCESS_DENIED, 0x58, # operation on the object/resource was denied
          :DBUS_SERVICE, 0x59, # error from a dbus service
          :STORAGE_VOL_EXIST, 0x5a, # the storage vol already exists
          :CPU_INCOMPATIBLE, 0x5b, # given CPU is incompatible with host CPU
          :XML_INVALID_SCHEMA, 0x5c, # XML document doesn't validate against schema
          :MIGRATE_FINISH_OK, 0x5d, # Finish API succeeded but it is expected to return NULL
          :AUTH_UNAVAILABLE, 0x5e, # authentication unavailable
          :NO_SERVER, 0x5f, # Server was not found
          :NO_CLIENT, 0x60, # Client was not found
          :AGENT_UNSYNCED, 0x61, # guest agent replies with wrong id to guest-sync command (DEPRECATED)
          :LIBSSH, 0x62, # error in libssh transport driver
          :DEVICE_MISSING, 0x63, # fail to find the desired device
          :INVALID_NWFILTER_BINDING, 0x64, # invalid nwfilter binding
          :NO_NWFILTER_BINDING, 0x65, # no nwfilter binding
          :INVALID_DOMAIN_CHECKPOINT, 0x66, # invalid domain checkpoint
          :NO_DOMAIN_CHECKPOINT, 0x67, # domain checkpoint not found
          :NO_DOMAIN_BACKUP, 0x68, # domain backup job id not found
          :INVALID_NETWORK_PORT, 0x69, # invalid network port object
          :NETWORK_PORT_EXIST, 0x6a, # the network port already exist
          :NO_NETWORK_PORT, 0x6b, # network port not found
          :NO_HOSTNAME, 0x6c # no domain's hostname found
      ]

      # struct virError {
      #   int 	code # The error code, a virErrorNumber
      #   int 	domain #   What part of the library raised this error
      #   char * 	message #   human-readable informative error message
      #   virErrorLevel 	level #   how consequent is the error
      #   virConnectPtr 	conn #   connection if available, deprecated see note above
      #   virDomainPtr 	dom #   domain if available, deprecated see note above
      #   char * 	str1 #   extra string information
      #   char * 	str2 #   extra string information
      #   char * 	str3 #   extra string information
      #   int 	int1 #   extra number information
      #   int 	int2 #   extra number information
      #   virNetworkPtr 	net #   network if available, deprecated see note above
      # }
      class Struct < ::FFI::Struct
        layout :code, FFI::Error.enum_type(:error_number),
               :domain, FFI::Error.enum_type(:error_domain),
               :message, :string,
               :level, FFI::Error.enum_type(:error_level),
               :conn, :pointer,
               :dom, :pointer,
               :str1, :string,
               :str2, :string,
               :str3, :string,
               :int1, :int,
               :int2, :int,
               :net, :pointer
      end

      # virErrorPtr	virGetLastError (
      #   void
      # )
      attach_function :virGetLastError, [], :pointer

    end
  end
end
