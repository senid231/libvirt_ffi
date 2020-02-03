# frozen_string_literal: true

module Libvirt
  module FFI
    module Libvirt
      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      # int	virGetVersion	(
      #   unsigned long *libVer,
      #   const char *type,
      #   unsigned long *typeVer
      # )
      attach_function :virGetVersion, [:pointer, :string, :pointer], :int
    end
  end
end
