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
        Util.log(:debug) { "Finalize Libvirt::Stream 0x#{obj_id.to_s(16)} @stream_ptr=#{@stream_ptr}, @cb=#{@cb}, @opaque=#{@opaque}," }
        return unless @stream_ptr

        if @cb
          rcb_result = FFI::Stream.virStreamEventRemoveCallback(@stream_ptr)
          warn("Couldn't remove callback Libvirt::Stream (0x#{obj_id.to_s(16)}) pointer #{@stream_ptr.address}") if rcb_result.negative?
          ab_result = FFI::Stream.virStreamAbort(@stream_ptr)
          warn("Couldn't abort Libvirt::Stream (0x#{obj_id.to_s(16)}) pointer #{@stream_ptr.address}") if ab_result.negative?
        end
        fr_result = FFI::Stream.virStreamFree(@stream_ptr)
        warn("Couldn't free Libvirt::Stream (0x#{obj_id.to_s(16)}) pointer #{@stream_ptr.address}") if fr_result.negative?
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
      dbg { "#event_add_callback events=#{events}, opaque=#{opaque}" }

      raise Errors::LibError, 'callback already added' unless @cb.nil?

      @opaque = opaque
      @cb = FFI::Stream.callback_function(:virStreamEventCallback) do |_stream_ptr, evs, _op|
        # stream = Stream.new(stream_ptr)
        block.call(self, evs, @opaque)
      end

      result = FFI::Stream.virStreamEventAddCallback(@stream_ptr, events, @cb, nil, nil)
      raise Errors::LibError, "Couldn't add stream event callback" if result.negative?

      true
    end

    # @param events [Integer] bit OR of EVENT_READABLE, EVENT_READABLE
    def event_update_callback(events)
      dbg { "#event_update_callback events=#{events}" }

      result = FFI::Stream.virStreamEventUpdateCallback(@stream_ptr, events)
      raise Errors::LibError, "Couldn't remove stream event callback" if result.negative?

      true
    end

    def event_remove_callback
      dbg { '#event_remove_callback' }

      result = FFI::Stream.virStreamEventRemoveCallback(@stream_ptr)
      raise Errors::LibError, "Couldn't remove stream event callback" if result.negative?

      opaque = @opaque
      @cb = nil
      @opaque = nil
      opaque
    end

    def finish
      result = FFI::Stream.virStreamFinish(@stream_ptr)
      raise Errors::LibError, "Couldn't remove stream event callback" if result.negative?

      @cb = nil
      @opaque = nil
    end

    def abort_stream
      result = FFI::Stream.virStreamAbort(@stream_ptr)
      raise Errors::LibError, "Couldn't remove stream event callback" if result.negative?

      @cb = nil
      @opaque = nil
    end

    def free_stream
      result = FFI::Stream.virStreamFree(@stream_ptr)
      raise Errors::LibError, "Couldn't free stream event callback" if result.negative?

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
      elsif result.zero?
        [0, nil]
      elsif result == -2
        [-2, nil]
      elsif result.positive?
        [result, buffer.read_bytes(result)]
      else
        raise Errors::LibError, "Invalid response from virStreamRecv #{result.inspect}"
      end
    end

    private

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Stream', &block)
    end
  end
end
