# frozen_string_literal: true

module Libvirt
  module FFI
    module Interface
      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      ## Variables

      ## Enums

      # enum virConnectListAllInterfacesFlags
      enum :list_all_flags, [
          :INACTIVE, 0x1,
          :ACTIVE, 0x2
      ]

      # enum virInterfaceXMLFlags
      enum :xml_flags, [
          :INACTIVE, 0x1 # dump inactive interface information
      ]

      ## Functions

      # int virConnectListAllInterfaces (
      #   virConnectPtr conn,
      #   virInterfacePtr ** ifaces,
      #   unsigned int flags
      # )
      attach_function :virConnectListAllInterfaces,
                      [:pointer, :pointer, :list_all_flags],
                      :int

      # int virConnectListDefinedInterfaces (
      #   virConnectPtr conn,
      #   char ** const names,
      #   int maxnames
      # )
      attach_function :virConnectListDefinedInterfaces,
                      [:pointer, :pointer, :int],
                      :int

      # int virConnectListInterfaces (
      #   virConnectPtr conn,
      #   char ** const names,
      #   int maxnames
      # )
      attach_function :virConnectListInterfaces,
                      [:pointer, :pointer, :int],
                      :int

      # int virConnectNumOfDefinedInterfaces (virConnectPtr conn)
      attach_function :virConnectNumOfDefinedInterfaces,
                      [:pointer],
                      :int

      # int virConnectNumOfInterfaces (virConnectPtr conn)
      attach_function :virConnectNumOfInterfaces,
                      [:pointer],
                      :int

      # int virInterfaceChangeBegin (
      #   virConnectPtr conn,
      #   unsigned int flags
      # )
      attach_function :virInterfaceChangeBegin,
                      [:pointer, :uint],
                      :int

      # int virInterfaceChangeCommit (
      #   virConnectPtr conn,
      #   unsigned int flags
      # )
      attach_function :virInterfaceChangeCommit,
                      [:pointer, :uint],
                      :int

      # int virInterfaceChangeRollback (
      #   virConnectPtr conn,
      #   unsigned int flags
      # )
      attach_function :virInterfaceChangeRollback,
                      [:pointer, :uint],
                      :int

      # int virInterfaceCreate (
      #   virInterfacePtr iface,
      #   unsigned int flags
      # )
      attach_function :virInterfaceCreate,
                      [:pointer, :uint],
                      :int

      # virInterfacePtr  virInterfaceDefineXML (
      #   virConnectPtr conn,
      #   const char * xml,
      #   unsigned int flags
      # )
      attach_function :virInterfaceDefineXML,
                      [:pointer, :string, :uint],
                      :pointer

      # int virInterfaceDestroy (
      #   virInterfacePtr iface,
      #   unsigned int flags
      # )
      attach_function :virInterfaceDestroy,
                      [:pointer, :uint],
                      :int

      # int virInterfaceFree (virInterfacePtr iface)
      attach_function :virInterfaceFree,
                      [:pointer],
                      :int

      # virConnectPtr virInterfaceGetConnect (virInterfacePtr iface)
      attach_function :virInterfaceGetConnect,
                      [:pointer],
                      :int

      # const char * virInterfaceGetMACString (virInterfacePtr iface)
      attach_function :virInterfaceGetMACString,
                      [:pointer],
                      :string

      # const char * virInterfaceGetName (virInterfacePtr iface)
      attach_function :virInterfaceGetName,
                      [:pointer],
                      :string

      # char * virInterfaceGetXMLDesc (
      #   virInterfacePtr iface,
      #   unsigned int flags
      # )
      attach_function :virInterfaceGetXMLDesc,
                      [:pointer, :uint],
                      :string

      # int virInterfaceIsActive (virInterfacePtr iface)
      attach_function :virInterfaceIsActive,
                      [:pointer],
                      :int

      # virInterfacePtr virInterfaceLookupByMACString (
      #   virConnectPtr conn,
      #   const char * macstr
      # )
      attach_function :virInterfaceLookupByMACString,
                      [:pointer, :string],
                      :pointer

      # virInterfacePtr virInterfaceLookupByName (
      #   virConnectPtr conn,
      #   const char * name
      # )
      attach_function :virInterfaceLookupByName,
                      [:pointer, :string],
                      :pointer

      # int virInterfaceRef (virInterfacePtr iface)
      attach_function :virInterfaceRef,
                      [:pointer],
                      :int

      # int virInterfaceUndefine (virInterfacePtr iface)
      attach_function :virInterfaceUndefine,
                      [:pointer],
                      :int

      ## Helpers
    end
  end
end
