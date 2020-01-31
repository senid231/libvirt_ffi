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
      Util.logger.debug { "Libvirt::DomainCallbackStorage#allocate_struct" }

      cb_data_ptr = ::FFI::MemoryPointer.new(:char, CallbackDataStruct.size, false)
      cb_data = CallbackDataStruct.new(cb_data_ptr)
      cb_data_free_func = ::FFI::Function.new(:void, [:pointer]) do |pointer|
        Util.logger.debug { "Libvirt::DomainCallbackStorage cb_data_free_func triggered" }
        remove_struct(pointer: pointer)
      end
      [cb_data, cb_data_free_func]
    end

    def store_struct(cb_data, connection_pointer:, callback_id:, cb:, opaque:)
      Util.logger.debug { "Libvirt::DomainCallbackStorage#store_struct" }

      cb_data[:connection_pointer] = connection_pointer
      cb_data[:callback_id] = callback_id
      @inner_storage[connection_pointer.address][callback_id] = { cb: cb, opaque: opaque, pointer: cb_data.pointer }
    end

    def remove_struct(pointer: nil, connection_pointer: nil, callback_id: nil)
      Util.logger.debug { "Libvirt::DomainCallbackStorage#remove_struct pointer=#{pointer}, connection_pointer=#{connection_pointer}, callback_id=#{callback_id}," }

      if pointer
        cb_data_struct = CallbackDataStruct.new(pointer)
        connection_pointer = cb_data_struct[:connection_pointer]
        callback_id = cb_data_struct[:callback_id]
      end

      cb_data = @inner_storage[connection_pointer.address].delete(callback_id)
      pointer ||= cb_data[:pointer]
      @inner_storage.delete(connection_pointer.address) if @inner_storage[connection_pointer.address].empty?

      #pointer.free
      cb_data[:opaque]
    end

    # @param [::FFI::Pointer]
    # @return [Array<2>] cb [Proc], opaque [Object]
    def retrieve_from_pointer(pointer)
      Util.logger.debug { "Libvirt::DomainCallbackStorage#retrieve_from_pointer pointer=#{pointer}," }

      cb_data_struct = CallbackDataStruct.new(pointer)
      connection_pointer = cb_data_struct[:connection_pointer]
      callback_id = cb_data_struct[:callback_id]
      cb_data = @inner_storage[connection_pointer.address][callback_id]
      [cb_data[:cb], cb_data[:opaque]]
    end
  end
end
