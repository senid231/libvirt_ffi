# frozen_string_literal: true

module Libvirt
  module FFI
    module Event
      extend ::FFI::Library
      extend Helpers
      ffi_lib Util.library_path

      # typedef void (*virEventHandleCallback)	(
      #   int watch,
      # 	int fd,
      # 	int events,
      # 	void * opaque
      # )
      EVENT_HANDLE_CALLBACK = callback :virEventHandleCallback, [:int, :int, :int, :pointer], :void

      # typedef void (*virEventTimeoutCallback)	(
      #   int timer,
      # 	void * opaque
      # )
      EVENT_TIMEOUT_CALLBACK = callback :virEventTimeoutCallback, [:int, :pointer], :void

      # typedef int	(*virEventAddHandleFunc) (
      #   int fd,
      # 	int event,
      # 	virEventHandleCallback cb,
      # 	void * opaque,
      # 	virFreeCallback ff
      # )
      callback :virEventAddHandleFunc, [
          :int,
          :int,
          :virEventHandleCallback,
          :pointer,
          FFI::Common::FREE_CALLBACK
      ], :int

      # typedef void	(*virEventUpdateHandleFunc)	(
      #   int watch,
      # 	int event
      # )
      callback :virEventUpdateHandleFunc, [:int, :int], :void

      # typedef int	(*virEventRemoveHandleFunc)	(
      #   int watch
      # )
      callback :virEventRemoveHandleFunc, [:int], :int

      # typedef int	(*virEventAddTimeoutFunc)	(
      #   int timeout,
      # 	virEventTimeoutCallback cb,
      # 	void * opaque,
      # 	virFreeCallback ff
      # )
      callback :virEventAddTimeoutFunc, [
          :int,
          :virEventTimeoutCallback,
          :pointer,
          FFI::Common::FREE_CALLBACK
      ], :int

      # typedef void (*virEventUpdateTimeoutFunc)	(
      #   int timer,
      # 	int timeout
      # )
      callback :virEventUpdateTimeoutFunc, [:int, :int], :void

      # typedef int	(*virEventRemoveTimeoutFunc)	(
      #   int timer
      # )
      callback :virEventRemoveTimeoutFunc, [:int], :int

      # void	virEventRegisterImpl (
      #   virEventAddHandleFunc addHandle,
      # 	virEventUpdateHandleFunc updateHandle,
      # 	virEventRemoveHandleFunc removeHandle,
      # 	virEventAddTimeoutFunc addTimeout,
      # 	virEventUpdateTimeoutFunc updateTimeout,
      # 	virEventRemoveTimeoutFunc removeTimeout
      # )
      attach_function :virEventRegisterImpl, [
          :virEventAddHandleFunc,
          :virEventUpdateHandleFunc,
          :virEventRemoveHandleFunc,
          :virEventAddTimeoutFunc,
          :virEventUpdateTimeoutFunc,
          :virEventRemoveTimeoutFunc
      ], :void

    end
  end
end
