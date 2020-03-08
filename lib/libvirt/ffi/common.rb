# frozen_string_literal: true

module Libvirt
  module FFI
    module Common
      # https://libvirt.org/html/libvirt-libvirt-common.html

      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      # typedef void (*virFreeCallback)	(
      #   void * opaque
      # )
      FREE_CALLBACK = callback :virFreeCallback, [:pointer], :void

      def self.free_function(*args, &block)
        callback_function(FREE_CALLBACK, *args, &block)
      end
    end
  end
end
