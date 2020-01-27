# frozen_string_literal: true

module Libvirt
  module FFI
    module Common
      extend ::FFI::Library
      ffi_lib Util.library_path

      # typedef void (*virFreeCallback)	(
      #   void * opaque
      # )
      FREE_CALLBACK = callback :virFreeCallback, [:pointer], :void
    end
  end
end
