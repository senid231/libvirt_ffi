# frozen_string_literal: true

module Libvirt
  module FFI
    module Stream
      extend ::FFI::Library
      ffi_lib Util.library_path

      # virStreamPtr virStreamNew (
      #   virConnectPtr conn,
      # 	unsigned int flags
      # )
      attach_function :virStreamNew, [:pointer, :uint], :pointer

      # typedef void (*virStreamEventCallback) (
      #   virStreamPtr stream,
      # 	int events,
      # 	void * opaque
      # )
      callback :virStreamEventCallback, [:pointer, :int, :pointer], :void

      # int	virStreamEventAddCallback	(
      #   virStreamPtr stream,
      # 	int events,
      # 	virStreamEventCallback cb,
      # 	void * opaque,
      # 	virFreeCallback ff
      # )
      attach_function :virStreamEventAddCallback, [
          :pointer,
          :int,
          :virStreamEventCallback,
          :pointer,
          FFI::Common::FREE_CALLBACK
      ], :int

      # int	virStreamEventRemoveCallback (
      #   virStreamPtr stream
      # )
      attach_function :virStreamEventRemoveCallback, [:pointer], :int

      # int	virStreamEventUpdateCallback (
      #   virStreamPtr stream,
      #   int events
      # )
      attach_function :virStreamEventUpdateCallback, [:pointer, :int], :int

      # int	virStreamFinish	(
      #   virStreamPtr stream
      # )
      attach_function :virStreamFinish, [:pointer], :int

      # int	virStreamFree	(
      #   virStreamPtr stream
      # )
      attach_function :virStreamFree, [:pointer], :int

      # int	virStreamAbort (
      #   virStreamPtr stream
      # )
      attach_function :virStreamAbort, [:pointer], :int

      # int	virStreamRecv (
      #   virStreamPtr stream,
      # 	char *data,
      # 	size_t nbytes
      # )
      attach_function :virStreamRecv, [:pointer, :pointer, :size_t], :int

    end
  end
end
