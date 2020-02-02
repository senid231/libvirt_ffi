# frozen_string_literal: true

module Libvirt
  class DomainCallbackStorage

    class CallbackDataStruct < ::FFI::Struct
      layout :connection_pointer, :pointer,
             :callback_id, :int
    end

    def initialize
      @inner_storage = Hash.new { |h, key| h[key] = {} }
    end

    # @return [Array<2>]
    #   cb_data [Libvirt::DomainCallbackStorage::CallbackDataStruct],
    #   cb_data_free_func [FFI::Function]
    def allocate_struct
      dbg { "#allocate_struct" }

      cb_data_ptr = ::FFI::MemoryPointer.new(:char, CallbackDataStruct.size, false)
      cb_data = CallbackDataStruct.new(cb_data_ptr)
      cb_data_free_func = ::FFI::Function.new(:void, [:pointer]) do |pointer|
        dbg { "Libvirt::DomainCallbackStorage cb_data_free_func triggered" }
        remove_struct(pointer)
      end
      [cb_data, cb_data_free_func]
    end

    def store_struct(cb_data, connection_pointer:, callback_id:, cb:, opaque:)
      dbg { "#store_struct" }

      cb_data[:connection_pointer] = connection_pointer
      cb_data[:callback_id] = callback_id
      @inner_storage[connection_pointer.address][callback_id] = { cb: cb, opaque: opaque, pointer: cb_data.pointer }
    end

    def remove_struct(pointer)
      dbg { "#remove_struct pointer=#{pointer}" }

      cb_data_struct = CallbackDataStruct.new(pointer)
      connection_pointer = cb_data_struct[:connection_pointer]
      callback_id = cb_data_struct[:callback_id]
      dbg { "#remove_struct pointer=#{pointer}, connection_pointer=#{connection_pointer}, callback_id=#{callback_id}," }

      cb_data = @inner_storage[connection_pointer.address].delete(callback_id)
      @inner_storage.delete(connection_pointer.address) if @inner_storage[connection_pointer.address].empty?

      cb_data[:opaque]
    end

    # @param [::FFI::Pointer]
    # @return [Array<2>] cb [Proc], opaque [Object]
    def retrieve_from_pointer(pointer)
      dbg { "#retrieve_from_pointer pointer=#{pointer}," }

      cb_data_struct = CallbackDataStruct.new(pointer)
      connection_pointer = cb_data_struct[:connection_pointer]
      callback_id = cb_data_struct[:callback_id]
      cb_data = @inner_storage[connection_pointer.address][callback_id]
      [cb_data[:cb], cb_data[:opaque]]
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::DomainCallbackStorage', &block)
    end
  end
end
