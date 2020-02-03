#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'libvirt'
require 'logger'
require 'active_support/all'
require 'async'
require 'get_process_mem'
require 'gc_tracer'

require_relative 'support/libvirt_async'
require_relative 'support/log_formatter'

GC::Tracer.start_logging(
    nil,
    gc_stat: false,
    gc_latest_gc_info: false,
    rusage: false,
    events: %i[end_mark end_sweep]
)

Libvirt.logger = Logger.new(STDOUT, formatter: LogFormatter.new)
Libvirt.logger.level = ENV['DEBUG'] ? :debug : :info

IMPL = LibvirtAsync::Implementations.new
OBJECTS = {
    hv: nil
}

def async_task(run, parent = nil, &block)
  task = LibvirtAsync::Util.create_task(parent, ASYNC_REACTOR, &block)
  case run
  when :now
    task.run
  when :later
    task.reactor << task.fiber
  else
    raise ArgumentError, "invalid run #{run}"
  end
end

Async do
  ASYNC_REACTOR = Async::Task.current.reactor

  puts "Lib version #{Libvirt.lib_version}"
  puts "Gem version #{Libvirt::VERSION}"

  IMPL.start

  OBJECTS[:hv] = Libvirt::Connection.new('qemu+tcp://localhost:16510/system')
  OBJECTS[:hv].open
  OBJECTS[:hv].register_close_callback do |conn, reason, _op|
    puts "Im closing conn=#{conn}, reason=#{reason}"
  end
  # OBJECTS[:hv].set_keep_alive(2, 1)

  ASYNC_REACTOR.every(5) do
    async_task(:now) do
      puts "list_all_domains_qty #{OBJECTS[:hv].list_all_domains_qty}"
    end
  end
end
