#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'libvirt'
require 'logger'
require 'active_support/all'
require 'async'
require 'get_process_mem'

require_relative 'support/libvirt_async'
require_relative 'support/log_formatter'

Libvirt.logger = Logger.new(STDOUT, formatter: LogFormatter.new)
Libvirt.logger.level = ENV['DEBUG'] ? :debug : :info

LibvirtAsync.logger = Logger.new(STDOUT, formatter: LogFormatter.new)
LibvirtAsync.logger.level = ENV['LIBVIRT_DEBUG'] ? :debug : :info

def print_usage(msg)
  mem = GetProcessMem.new
  STDOUT.puts "#{msg} [#{mem.mb}MB]"
end

def run_gc(msg)
  print_usage "#{msg} before GC.start"
  GC.start
  print_usage "#{msg} after GC.start"
end

IMPL = LibvirtAsync::Implementations.new
CONNS = []
DOMS = []
STREAMS = { stream: nil }

class ScreenshotOpaque
  CALLBACK = proc do |s, ev, op|
    #run_gc('ScreenshotOpaque CALLBACK start')
    next unless (Libvirt::Stream::EVENT_READABLE & ev) != 0
    begin
      code, data = s.recv(1024)
    rescue Libvirt::Error => e
      op.on_libvirt_error(s, e)
      next
    end
    #run_gc('ScreenshotOpaque CALLBACK after recv')

    case code
    when 0
      op.on_complete(s)
    when -1
      op.on_recv_error(s)
    when -2
      print_usage "Opaque::CALLBACK #{op.filepath} wait for data"
    else
      op.on_receive(data)
    end
  end

  attr_reader :filepath

  def initialize(filepath, finish_cb)
    @filepath = filepath
    @f = File.open(@filepath, 'wb')
    @finish_cb = finish_cb
  end

  def on_complete(stream)
    print_usage "Opaque#on_complete #{@filepath}"
    success, reason = finish_stream(stream)
    finish(success, reason)
  end

  def on_receive(data)
    print_usage "Opaque#on_receive #{@filepath} #{data&.size}"
    @f.write(data)
  end

  def on_recv_error(stream)
    print_usage "Opaque#on_recv_error #{@filepath}"
    success, reason = finish_stream(stream)
    finish(success, reason)
  end

  def on_libvirt_error(stream, e)
    print_usage "Opaque#on_libvirt_error #{@filepath} #{e}"
    success, reason = finish_stream(stream)
    finish(success, reason)
  end

  private

  def finish_stream(stream)
    print_usage "Opaque#finish_stream stream.event_remove_callback #{@filepath}"
    stream.event_remove_callback
    result = begin
      print_usage "Opaque#finish_stream stream.finish #{@filepath}"
      stream.finish
      [true, nil]
    rescue Libvirt::Error => e
      STDERR.puts "Opaque#finish_stream stream.finish exception rescued #{e.class} #{e.message}"
      [false, e.message]
    end
    print_usage "Opaque#finish_stream ends #{@filepath}"
    result
  end

  def finish(success, reason)
    print_usage "Opaque#finish success=#{success} #{@filepath}"

    @f.close
    @f = nil
    @finish_cb.call(success, reason)
    @finish_cb = nil
  end
end

def save_screenshot(c, domain, i)
  stream = c.stream(Libvirt::Stream::NONBLOCK)

  opaque_cb = proc do |success|
    puts "Stream #{i} complete success=#{success}"
    print_usage "after stream #{i} complete stream=#{STREAMS["stream#{i}"]}"
    run_gc("Stream #{i} complete before remove stream")
    print_usage "after stream #{i} complete and GC.start"
    STREAMS["stream#{i}"] = nil
    run_gc("Stream #{i} complete before remove stream")
    print_usage "after stream #{i} delete and GC.start"
  end

  opaque = ScreenshotOpaque.new("tmp/screenshots_test#{i}.pnm", opaque_cb)

  STREAMS["stream#{i}"] = stream

  print_usage "test_screenshot_mem #{i} before stream start"
  domain.screenshot(stream, 0)
  stream.event_add_callback(
      Libvirt::Stream::EVENT_READABLE,
      opaque,
      &ScreenshotOpaque::CALLBACK
  )
  run_gc("Stream #{i} after add event")
end

Async do
  ASYNC_REACTOR = Async::Task.current.reactor

  puts "Lib version #{Libvirt.lib_version}"
  puts "Gem version #{Libvirt::VERSION}"

  IMPL.start

  c = Libvirt::Connection.new('qemu+tcp://localhost:16510/system')
  c.open
  res = c.set_keep_alive(2, 1)
  Libvirt.logger.info { "set_keep_alive #{res}" }
  CONNS.push(c)

  domain = c.list_all_domains.first
  DOMS.push(domain)

  print_usage "First generation"
  5.times do |i|
    save_screenshot(c, domain, 100 + i)
  end

  ASYNC_REACTOR.after(15) do
    Async::Task.new(ASYNC_REACTOR, nil) do
      print_usage "Second generation"

      con = CONNS.first
      dom = DOMS.first
      5.times do |i|
        save_screenshot(con, dom, 200 + i)
      end
    end.run
  end

  ASYNC_REACTOR.after(30) do
    Async::Task.new(ASYNC_REACTOR, nil) do
      print_usage "Third generation"

      con = CONNS.first
      dom = DOMS.first
      5.times do |i|
        save_screenshot(con, dom, 300 + i)
      end
    end.run
  end

  ASYNC_REACTOR.every(5) do
    Async::Task.new(ASYNC_REACTOR, nil) do
      run_gc 'PERIODIC'
    end.run
  end

end
