# frozen_string_literal: true

module Libvirt
  class Stream
    NONBLOCK = 0x1
    EVENT_READABLE = 0x1
    EVENT_WRITABLE = 0x2

    def initialize(stream_ptr)
      @stream_ptr = stream_ptr
      @cb = nil
      @opaque = nil

      free = ->(obj_id) do
        return unless @stream_ptr
        if @cb
          rcb_result = FFI::Stream.virStreamEventRemoveCallback(@stream_ptr)
          STDERR.puts("Couldn't remove callback Libvirt::Stream (0x#{obj_id.to_s(16)}) pointer #{@stream_ptr.address}") if rcb_result < 0
          ab_result = FFI::Stream.virStreamAbort(@stream_ptr)
          STDERR.puts("Couldn't abort Libvirt::Stream (0x#{obj_id.to_s(16)}) pointer #{@stream_ptr.address}") if ab_result < 0
        end
        fr_result = FFI::Stream.virStreamFree(@stream_ptr)
        STDERR.puts("Couldn't free Libvirt::Stream (0x#{obj_id.to_s(16)}) pointer #{@stream_ptr.address}") if fr_result < 0
      end
      ObjectSpace.define_finalizer(self, free)
    end

    def to_ptr
      @stream_ptr
    end

    # @param events [Integer] bit OR of EVENT_READABLE, EVENT_READABLE
    # @param opaque [Object]
    # @yield [Stream]
    def event_add_callback(events, opaque, &block)
      raise Error, 'callback already added' unless @cb.nil?

      @opaque = opaque
      @cb = ::FFI::Function.new(:void, [:pointer, :int, :pointer]) do |_stream_ptr, evs, _op|
        # stream = Stream.new(stream_ptr)
        block.call(self, evs, @opaque)
      end

      result = FFI::Stream.virStreamEventAddCallback(@stream_ptr, events, @cb, nil, nil)
      raise Error, "Couldn't add stream event callback" if result < 0

      true
    end

    # @param events [Integer] bit OR of EVENT_READABLE, EVENT_READABLE
    def event_update_callback(events)
      result = FFI::Stream.virStreamEventUpdateCallback(@stream_ptr, events)
      raise Error, "Couldn't remove stream event callback" if result < 0
      true
    end

    def event_remove_callback
      result = FFI::Stream.virStreamEventRemoveCallback(@stream_ptr)
      raise Error, "Couldn't remove stream event callback" if result < 0
      opaque = @opaque
      @cb = nil
      @opaque = nil
      opaque
    end

    def finish
      result = FFI::Stream.virStreamFinish(@stream_ptr)
      raise Error, "Couldn't remove stream event callback" if result < 0
      @cb = nil
      @opaque = nil
    end

    def abort_stream
      result = FFI::Stream.virStreamAbort(@stream_ptr)
      raise Error, "Couldn't remove stream event callback" if result < 0
      @cb = nil
      @opaque = nil
    end

    def free_stream
      result = FFI::Stream.virStreamFree(@stream_ptr)
      raise Error, "Couldn't free stream event callback" if result < 0
      @cb = nil
      @opaque = nil
      @stream_ptr = nil
    end

    def recv(bytes)
      buffer = ::FFI::MemoryPointer.new(:char, bytes)
      result = FFI::Stream.virStreamRecv(@stream_ptr, buffer, bytes)
      if result == -1
        abort_stream
        [-1, nil]
      elsif result == 0
        [0, nil]
      elsif result == -2
        [-2, nil]
      elsif result > 0
        [result, buffer.read_bytes(result)]
      else
        raise Error, "Invalid response from virStreamRecv #{result.inspect}"
      end
    end
  end
end
