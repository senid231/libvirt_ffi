# frozen_string_literal: true

module Libvirt
  module FFI
    module Connection
      extend ::FFI::Library
      ffi_lib Util.library_path

      # virConnectPtr	virConnectOpen (const char * name)
      attach_function :virConnectOpen, [:string], :pointer

      # int	virConnectGetVersion (virConnectPtr conn, unsigned long *hvVer)
      attach_function :virConnectGetVersion, [:pointer, :pointer], :int

      # int	virConnectSetKeepAlive (
      #   virConnectPtr conn,
      # 	int interval,
      # 	unsigned int count
      # )
      attach_function :virConnectSetKeepAlive, [:pointer, :int, :uint], :int
    end
  end
end
