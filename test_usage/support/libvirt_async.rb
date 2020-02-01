# frozen_string_literal: true

module LibvirtAsync
  class << self
    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger
    end
  end

  module WithDbg
    extend ActiveSupport::Concern

    class_methods do
      def dbg(progname = nil, &block)
        LibvirtAsync.logger&.debug(progname || "#{name}.:0x#{object_id.to_s(16)}", &block)
      end
    end

    private

    def dbg(progname = nil, &block)
      LibvirtAsync.logger&.debug(progname || "#{self.class}#:0x#{object_id.to_s(16)}", &block)
    end
  end

  module Util
    def create_task(parent = nil, reactor = nil, &block)
      parent = Async::Task.current? if parent == :current
      reactor ||= Async::Task.current.reactor
      Async::Task.new(reactor, parent, &block)
    end
    module_function :create_task
  end

  class Handle
    # Represents an event handle (usually a file descriptor).  When an event
    # happens to the handle, we dispatch the event to libvirt via
    # Libvirt::event_invoke_handle_callback (feeding it the handle_id we returned
    # from add_handle, the file descriptor, the new events, and the opaque
    # data that libvirt gave us earlier).

    class Monitor < Async::Wrapper
      def close
        cancel_monitor
      end

      def readiness
        monitor&.readiness
      end

      def to_s
        "#<#{self.class}:0x#{object_id.to_s(16)} readable=#{@readable&.object_id&.to_s(16)} writable=#{@writable&.object_id&.to_s(16)} alive=#{@monitor && !@monitor.closed?}>"
      end

      def inspect
        to_s
      end
    end

    include WithDbg

    attr_reader :handle_id, :fd, :opaque, :monitor
    attr_accessor :events

    def initialize(handle_id, fd, events, opaque)
      dbg { "#{self.class}#initialize handle_id=#{handle_id}, fd=#{fd}, events=#{events}" }

      @handle_id = handle_id
      @fd = fd
      @events = events
      @opaque = opaque
      @monitor = nil
    end

    def register
      dbg { "#{self.class}#register handle_id=#{handle_id}, fd=#{fd}" }

      if (events & Libvirt::EVENT_HANDLE_ERROR) != 0
        dbg { "#{self.class}#register skip EVENT_HANDLE_ERROR handle_id=#{handle_id}, fd=#{fd}" }
      end
      if (events & Libvirt::EVENT_HANDLE_HANGUP) != 0
        dbg { "#{self.class}#register skip EVENT_HANDLE_HANGUP handle_id=#{handle_id}, fd=#{fd}" }
      end

      interest = events_to_interest(events)
      dbg { "#{self.class}#register parse handle_id=#{handle_id}, fd=#{fd}, events=#{events}, interest=#{interest}" }

      if interest.nil?
        dbg { "#{self.class}#register no interest handle_id=#{handle_id}, fd=#{fd}" }
        return
      end

      task = Util.create_task do
        dbg { "#{self.class}#register_handle Async start handle_id=#{handle_id}, fd=#{fd}" }
        io_mode = interest_to_io_mode(interest)

        io = IO.new(fd, io_mode, autoclose: false)
        @monitor = Monitor.new(io)

        while @monitor.readiness == nil
          cancelled = wait_io(interest)

          if cancelled
            dbg { "#{self.class}#register_handle async cancel handle_id=#{handle_id}, fd=#{fd}" }
            break
          end

          dbg { "#{self.class}#register_handle async resumes readiness=#{@monitor.readiness}, handle_id=#{handle_id}, fd=#{fd}" }
          events = readiness_to_events(@monitor.readiness)

          unless events.nil?
            dispatch(events)
            break
          end

          dbg { "#{self.class}#register_handle async not ready readiness=#{@monitor.readiness}, handle_id=#{handle_id}, fd=#{fd}" }
        end

      end

      dbg { "#{self.class}#register_handle invokes fiber=0x#{task.fiber.object_id.to_s(16)} handle_id=#{handle_id}, fd=#{fd}" }
      task.run
      dbg { "#{self.class}#register_handle ends handle_id=#{handle_id}, fd=#{fd}" }
    end

    def unregister
      dbg { "#{self.class}#unregister handle_id=#{handle_id}, fd=#{fd}" }

      if @monitor.nil?
        dbg { "#{self.class}#unregister already unregistered handle_id=#{handle_id}, fd=#{fd}" }
        return
      end

      @monitor.close
      @monitor = nil
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} handle_id=#{handle_id} fd=#{fd} events=#{events} monitor=#{monitor}>"
    end

    def inspect
      to_s
    end

    private

    def dispatch(events)
      dbg { "#{self.class}#dispatch starts handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }

      task = Util.create_task do
        dbg { "#{self.class}#dispatch async starts handle_id=#{handle_id} events=#{events}, fd=#{fd}" }
        # Libvirt::event_invoke_handle_callback(handle_id, fd, events, opaque)
        # opaque.call_cb(handle_id, fd, events)
        Libvirt::Event.invoke_handle_callback(handle_id, fd, events, opaque)
        dbg { "#{self.class}#dispatch async ends handle_id=#{handle_id} received_events=#{events}, fd=#{fd}" }
      end
      # dbg { "#{self.class}#dispatch invokes fiber=0x#{task.fiber.object_id.to_s(16)} handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }
      # task.run
      # dbg { "#{self.class}#dispatch ends handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }
      dbg { "#{self.class}#dispatch schedules fiber=0x#{task.fiber.object_id.to_s(16)} handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }
      task.reactor << task.fiber
    end

    def wait_io(interest)
      meth = interest_to_monitor_method(interest)
      begin
        @monitor.public_send(meth)
        false
      rescue Monitor::Cancelled => e
        dbg { "#{self.class}#wait_io cancelled #{e.class} #{e.message}" }
        true
      end
    end

    def interest_to_monitor_method(interest)
      case interest
      when :r
        :wait_readable
      when :w
        :wait_writable
      when :rw
        :wait_any
      else
        raise ArgumentError, "invalid interest #{interest}"
      end
    end

    def events_to_interest(events)
      readable = (events & Libvirt::EVENT_HANDLE_READABLE) != 0
      writable = (events & Libvirt::EVENT_HANDLE_WRITABLE) != 0
      if readable && writable
        :rw
      elsif readable
        :r
      elsif writable
        :w
      else
        nil
      end
    end

    def interest_to_io_mode(interest)
      case interest
      when :rw
        'a+'
      when :r
        'r'
      when :w
        'w'
      else
        raise ArgumentError, "invalid interest #{interest}"
      end
    end

    def readiness_to_events(readiness)
      case readiness&.to_sym
      when :rw
        Libvirt::EVENT_HANDLE_READABLE | Libvirt::EVENT_HANDLE_WRITABLE
      when :r
        Libvirt::EVENT_HANDLE_READABLE
      when :w
        Libvirt::EVENT_HANDLE_WRITABLE
      else
        nil
      end
    end
  end

  class Timer
    # Represents a   When a timer expires, we dispatch the event to
    # libvirt via Libvirt::event_invoke_timeout_callback (feeding it the timer_id
    # we returned from add_timer and the opaque data that libvirt gave us
    # earlier).

    class Monitor
      class Cancelled < StandardError
        def initialize
          super('was cancelled')
        end
      end

      attr_reader :fiber

      def initialize
        @fiber = nil
      end

      def wait(timeout)
        @fiber = Async::Task.current.fiber
        Async::Task.current.sleep(timeout)
        @fiber = nil
      end

      def close
        @fiber.resume(Cancelled.new) if @fiber&.alive?
        @fiber = nil
      end

      def to_s
        "#<#{self.class}:0x#{object_id.to_s(16)} fiber=#{@fiber&.object_id&.to_s(16)} alive=#{@fiber&.alive?}>"
      end

      def inspect
        to_s
      end
    end

    include WithDbg

    attr_reader :timer_id, :opaque, :monitor
    attr_accessor :last_fired, :interval

    def initialize(timer_id, interval, opaque)
      dbg { "#{self.class}#initialize timer_id=#{timer_id}, interval=#{interval}" }

      @timer_id = timer_id
      @interval = interval.to_f / 1000.to_f
      @opaque = opaque
      @last_fired = Time.now.to_f
      @monitor = nil
    end

    def wait_time
      return if interval < 0
      last_fired + interval
    end

    def register
      dbg { "#{self.class}#register starts timer_id=#{timer_id}, interval=#{interval}" }

      if wait_time.nil?
        dbg { "#{self.class}#register no wait time timer_id=#{timer_id}, interval=#{interval}" }
        return
      end

      task = Util.create_task do
        dbg { "#{self.class}#register async starts timer_id=#{timer_id}, interval=#{interval}" }
        now_time = Time.now.to_f
        timeout = wait_time > now_time ? wait_time - now_time : 0
        @monitor = Monitor.new
        cancelled = wait_timer(timeout)

        if cancelled
          dbg { "#{self.class}#register async cancel timer_id=#{timer_id}, interval=#{interval}" }
        else
          dbg { "#{self.class}#register async ready timer_id=#{timer_id}, interval=#{interval}" }
          self.last_fired = Time.now.to_f
          dispatch
        end
      end

      dbg { "#{self.class}#register invokes fiber=0x#{task.fiber.object_id.to_s(16)} timer_id=#{timer_id}, interval=#{interval}" }
      task.run
      dbg { "#{self.class}#register ends timer_id=#{timer_id}, interval=#{interval}" }
    end

    def unregister
      dbg { "#{self.class}#unregister_timer timer_id=#{timer_id}, interval=#{interval}" }

      if @monitor.nil?
        dbg { "#{self.class}#unregister_timer already unregistered timer_id=#{timer_id}, interval=#{interval}" }
        return
      end

      @monitor.close
      @monitor = nil
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} timer_id=#{timer_id} interval=#{interval} last_fired=#{last_fired} monitor=#{monitor}>"
    end

    def inspect
      to_s
    end

    private

    def dispatch
      dbg { "#{self.class}#dispatch starts timer_id=#{timer_id}, interval=#{interval}" }

      task = Util.create_task do
        dbg { "#{self.class}#dispatch async starts timer_id=#{timer_id}, interval=#{interval}" }
        # Libvirt::event_invoke_timeout_callback(timer_id, opaque)
        # opaque.call_cb(timer_id)
        Libvirt::Event.invoke_timeout_callback(timer_id, opaque)
        dbg { "#{self.class}#dispatch async async ends timer_id=#{timer_id}, interval=#{interval}" }
      end

      # dbg { "#{self.class}#dispatch invokes fiber=0x#{task.fiber.object_id.to_s(16)} timer_id=#{timer_id}, interval=#{interval}" }
      # task.run
      # dbg { "#{self.class}#dispatch ends timer_id=#{timer_id}, interval=#{interval}" }
      dbg { "#{self.class}#dispatch schedules fiber=0x#{task.fiber.object_id.to_s(16)} timer_id=#{timer_id}, interval=#{interval}" }
      task.reactor << task.fiber
    end

    def wait_timer(timeout)
      begin
        @monitor.wait(timeout)
        false
      rescue Monitor::Cancelled => e
        dbg { "#{self.class}#wait_timer cancelled #{e.class} #{e.message}" }
        true
      end
    end

  end

  class Implementations
    include WithDbg

    def initialize
      dbg { "#{self.class}#initialize" }

      default_variables
    end

    def start
      dbg { "#{self.class}#start" }

      register_implementations
    end

    def stop
      dbg { "#{self.class}#stop" }

      @handles.each(&:unregister)
      @timers.each(&:unregister)

      default_variables
    end

    def print_debug_info
      str = [
          "#{self.class}:0x#{object_id.to_s(16)}",
          "handles = [",
          @handles.map(&:to_s).join("\n"),
          "]",
          "timers = [",
          @timers.map(&:to_s).join("\n"),
          "]"
      ].join("\n")
      Libvirt.logger&.debug { str }
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} handles=#{@handles} timers=#{@timers}>"
    end

    def inspect
      to_s
    end

    private

    def default_variables
      @next_handle_id = 1
      @next_timer_id = 1
      @handles = []
      @timers = []
    end

    def register_implementations
      dbg { "#{self.class}#register_implementations" }

      Libvirt::Event.register(
          add_handle: method(:add_handle).to_proc,
          update_handle: method(:update_handle).to_proc,
          remove_handle: method(:remove_handle).to_proc,
          add_timer: method(:add_timer).to_proc,
          update_timer: method(:update_timer).to_proc,
          remove_timer: method(:remove_timer).to_proc
      )
    end

    def add_handle(fd, events, opaque)
      # add a handle to be tracked by this object.  The application is
      # expected to maintain a list of internal handle IDs (integers); this
      # callback *must* return the current handle_id.  This handle_id is used
      # both by libvirt to identify the handle (during an update or remove
      # callback), and is also passed by the application into libvirt when
      # dispatching an event.  The application *must* also store the opaque
      # data given by libvirt, and return it back to libvirt later
      # (see remove_handle)
      dbg { "#{self.class}#add_handle starts fd=#{fd}, events=#{events}" }

      @next_handle_id += 1
      handle_id = @next_handle_id
      handle = LibvirtAsync::Handle.new(handle_id, fd, events, opaque)
      @handles << handle
      handle.register

      dbg { "#{self.class}#add_handle ends fd=#{fd}, events=#{events}" }
      handle_id
    end

    def update_handle(handle_id, events)
      # update a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and the new events.  It
      # is our responsibility to find the correct handle and update the events
      # it cares about
      dbg { "#{self.class}#update_handle starts handle_id=#{handle_id}, events=#{events}" }

      handle = @handles.detect { |h| h.handle_id == handle_id }
      handle.events = events
      handle.unregister
      handle.register

      dbg { "#{self.class}#update_handle ends handle_id=#{handle_id}, events=#{events}" }
      nil
    end

    def remove_handle(handle_id)
      # remove a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and it is our
      # responsibility to "forget" the handle.  We must return the opaque data
      # that libvirt handed us in "add_handle", otherwise we will leak memory
      dbg { "#{self.class}#remove_handle starts handle_id=#{handle_id}" }

      idx = @handles.index { |h| h.handle_id == handle_id }
      handle = @handles.delete_at(idx)
      handle.unregister

      dbg { "#{self.class}#remove_handle starts handle_id=#{handle_id}" }
      handle.opaque
    end

    def add_timer(interval, opaque)
      # add a timeout to be tracked by this object.  The application is
      # expected to maintain a list of internal timer IDs (integers); this
      # callback *must* return the current timer_id.  This timer_id is used
      # both by libvirt to identify the timeout (during an update or remove
      # callback), and is also passed by the application into libvirt when
      # dispatching an event.  The application *must* also store the opaque
      # data given by libvirt, and return it back to libvirt later
      # (see remove_timer)
      dbg { "#{self.class}#add_timer starts interval=#{interval}" }

      @next_timer_id += 1
      timer_id = @next_timer_id
      timer = LibvirtAsync::Timer.new(timer_id, interval, opaque)
      @timers << timer
      timer.register

      dbg { "#{self.class}#add_timer ends interval=#{interval}" }
      timer_id
    end

    def update_timer(timer_id, interval)
      # update a previously registered timer.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and the new interval.  It
      # is our responsibility to find the correct timer and update the timers
      # it cares about
      dbg { "#{self.class}#update_timer starts timer_id=#{timer_id}, interval=#{interval}" }

      timer = @timers.detect { |t| t.timer_id == timer_id }
      dbg { "#{self.class}#update_timer updating timer_id=#{timer.timer_id}" }
      timer.interval = interval
      timer.unregister
      timer.register

      dbg { "#{self.class}#update_timer ends timer_id=#{timer_id}, interval=#{interval}" }
      nil
    end

    def remove_timer(timer_id)
      # remove a previously registered timeout.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and it is our
      # responsibility to "forget" the timer.  We must return the opaque data
      # that libvirt handed us in "add_timer", otherwise we will leak memory
      dbg { "#{self.class}#remove_timer starts timer_id=#{timer_id}" }

      idx = @timers.index { |t| t.timer_id == timer_id }
      timer = @timers.delete_at(idx)
      timer.unregister

      dbg { "#{self.class}#remove_timer ends timer_id=#{timer_id}" }
      timer.opaque
    end
  end
end
