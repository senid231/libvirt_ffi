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

    Opaque = Struct.new(:cb, :opaque, :free_func)

    def invoke_handle_callback(watch, fd, events, opaque)
      cb = opaque.cb
      op = opaque.opaque
      dbg { "INVOKE_HANDLE_CALLBACK watch=#{watch} fd=#{fd} events=#{events} op=#{op}" }
      cb.call(watch, fd, events, op)
    end

    def invoke_timeout_callback(timer, opaque)
      cb = opaque.cb
      op = opaque.opaque
      dbg { "INVOKE_TIMEOUT_CALLBACK timer=#{timer} op=#{op}" }
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

    def schedule_operation(&block)
      @schedule.call(&block)
    end

    def register(add_handle:, update_handle:, remove_handle:, add_timer:, update_timer:, remove_timer:, schedule:) # rubocop:disable Metrics/ParameterLists
      @add_handle = add_handle
      @update_handle = update_handle
      @remove_handle = remove_handle
      @add_timer = add_timer
      @update_timer = update_timer
      @remove_timer = remove_timer
      @schedule = schedule

      @add_handle_cb = FFI::Event.callback_function(:virEventAddHandleFunc, &method(:_add_handle))
      @update_handle_cb = FFI::Event.callback_function(:virEventUpdateHandleFunc, &method(:_update_handle))
      @remove_handle_cb = FFI::Event.callback_function(:virEventRemoveHandleFunc, &method(:_remove_handle))
      @add_timer_cb = FFI::Event.callback_function(:virEventAddTimeoutFunc, &method(:_add_timer))
      @update_timer_cb = FFI::Event.callback_function(:virEventUpdateTimeoutFunc, &method(:_update_timer))
      @remove_timer_cb = FFI::Event.callback_function(:virEventRemoveTimeoutFunc, &method(:_remove_timer))

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

    def _add_handle(fd, event, cb, opaque, free_func)
      dbg { "ADD_HANDLE fd=#{fd}, #{event}=event, cb=#{cb}, opaque=#{opaque}, free_func=#{free_func}" }
      op = Opaque.new(cb, opaque, free_func)
      @add_handle.call(fd, event, op)
    end

    def _update_handle(watch, event)
      dbg { "UPDATE_HANDLE watch=#{watch}, event=#{event}" }
      @update_handle.call(watch, event)
    end

    def _remove_handle(watch)
      dbg { "REMOVE_HANDLE watch=#{watch}" }
      op = @remove_handle.call(watch)
      free_func = op.free_func
      opaque = op.opaque
      schedule_operation do
        dbg { "REMOVE_HANDLE delayed free_func watch=#{watch}" }
        free_func.call(opaque) unless free_func.null?
      end
      0
    end

    def _add_timer(timeout, cb, opaque, free_func)
      dbg { "ADD_TIMER timeout=#{timeout}, cb=#{cb}, opaque=#{opaque}, free_func=#{free_func}" }
      op = Opaque.new(cb, opaque, free_func)
      @add_timer.call(timeout, op)
    end

    def _update_timer(timer, timeout)
      dbg { "UPDATE_TIMER timer=#{timer}, timeout=#{timeout}" }
      @update_timer.call(timer, timeout)
    end

    def _remove_timer(timer)
      dbg { "REMOVE_TIMER timer=#{timer}" }
      op = @remove_timer.call(timer)
      free_func = op.free_func
      opaque = op.opaque
      schedule_operation do
        dbg { "REMOVE_TIMER async free_func timer=#{timer}" }
        free_func.call(opaque) unless free_func.null?
      end
      0
    end

    def dbg(&block)
      Util.log(:debug, 'Libvirt::Event', &block)
    end
  end
end
