# frozen_string_literal: true

require 'singleton'
require 'forwardable'

module Libvirt
  class Event
    include Singleton
    extend Forwardable
    extend SingleForwardable

    single_delegate [
                        :register,
                        :unregister,
                        :registered?,
                        :debug,
                        :debug=,
                        :invoke_handle_callback,
                        :invoke_timeout_callback
                    ] => :instance

    attr_accessor :debug

    Opaque = Struct.new(:cb, :opaque, :ff)

    def invoke_handle_callback(watch, fd, events, opaque)
      cb = opaque.cb
      op = opaque.opaque
      dbg { "Libvirt::Event INVOKE_HANDLE_CALLBACK watch=#{watch} fd=#{fd} events=#{events} op=#{op}" }
      cb.call(watch, fd, events, op)
    end

    def invoke_timeout_callback(timer, opaque)
      cb = opaque.cb
      op = opaque.opaque
      dbg { "Libvirt::Event INVOKE_TIMEOUT_CALLBACK timer=#{timer} op=#{op}" }
      cb.call(timer, op)
    end

    def registered?
      @registered || false
    end

    def unregister
      @add_handle_cb = nil
      @update_handle_cb = nil
      @remove_handle_cb = nil
      @add_timer_cb = nil
      @update_timer_cb = nil
      @remove_timer_cb = nil
      @add_handle = nil
      @update_handle = nil
      @remove_handle = nil
      @add_timer = nil
      @update_timer = nil
      @remove_timer = nil

      @registered = false
      true
    end

    def register(add_handle:, update_handle:, remove_handle:, add_timer:, update_timer:, remove_timer:)
      @add_handle = add_handle
      @update_handle = update_handle
      @remove_handle = remove_handle
      @add_timer = add_timer
      @update_timer = update_timer
      @remove_timer = remove_timer

      @add_handle_cb = FFI::Event.event_add_handle_func(&method(:_add_handle).to_proc)
      @update_handle_cb = ::FFI::Function.new(:void, [:int, :int], &method(:_update_handle).to_proc)
      @remove_handle_cb = ::FFI::Function.new(:int, [:int], &method(:_remove_handle).to_proc)
      @add_timer_cb = FFI::Event.event_add_timeout_func(&method(:_add_timer).to_proc)
      @update_timer_cb = ::FFI::Function.new(:void, [:int, :int], &method(:_update_timer).to_proc)
      @remove_timer_cb = ::FFI::Function.new(:int, [:int], &method(:_remove_timer).to_proc)

      FFI::Event.virEventRegisterImpl(
          @add_handle_cb,
          @update_handle_cb,
          @remove_handle_cb,
          @add_timer_cb,
          @update_timer_cb,
          @remove_timer_cb
      )
      @registered = true
    end

    private

    def _add_handle(fd, event, cb, opaque, ff)
      dbg { "Libvirt::Event ADD_HANDLE fd=#{fd}, #{event}=event, cb=#{cb}, opaque=#{opaque}, ff=#{ff}" }
      op = Opaque.new(cb, opaque, ff)
      @add_handle.call(fd, event, op)
    end

    def _update_handle(watch, event)
      dbg { "Libvirt::Event UPDATE_HANDLE watch=#{watch}, event=#{event}" }
      @update_handle.call(watch, event)
    end

    def _remove_handle(watch)
      dbg { "Libvirt::Event REMOVE_HANDLE watch=#{watch}" }
      op = @remove_handle.call(watch)
      free_func = op.ff
      opaque = op.opaque
      free_func.call(opaque) unless free_func.null?
      0
    end

    def _add_timer(timeout, cb, opaque, ff)
      dbg { "Libvirt::Event ADD_TIMER timeout=#{timeout}, cb=#{cb}, opaque=#{opaque}, ff=#{ff}" }
      op = Opaque.new(cb, opaque, ff)
      @add_timer.call(timeout, op)
    end

    def _update_timer(timer, timeout)
      dbg { "Libvirt::Event UPDATE_TIMER timer=#{timer}, timeout=#{timeout}" }
      @update_timer.call(timer, timeout)
    end

    def _remove_timer(timer)
      dbg { "Libvirt::Event REMOVE_TIMER timer=#{timer}" }
      op = @remove_timer.call(timer)
      free_func = op.ff
      opaque = op.opaque
      free_func.call(opaque) unless free_func.null?
      0
    end

    def dbg(&block)
      return unless debug

      Util.log(:debug, &block)
    end

  end
end
