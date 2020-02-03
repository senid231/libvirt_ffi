module Libvirt
  module FFI
    module Helpers
      # Creates function by provided callback or callback name
      # @param callback [Symbol,FFI::CallbackInfo] callback name registered in current module
      # @param args [Array] extra arguments for FFI::Function
      # @yield when function is called
      # @return [FFI::Function]
      def callback_function(callback, *args, &block)
        callback_info = callback.is_a?(Symbol) ? find_type(callback) : callback
        ::FFI::Function.new(callback_info.result_type, callback_info.param_types, *args, &block)
      end
    end
  end
end
