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
CONNS = []
DOMS = []
CB_IDS = []

Async do
  ASYNC_REACTOR = Async::Task.current.reactor

  puts "Lib version #{Libvirt.lib_version}"
  puts "Gem version #{Libvirt::VERSION}"

  IMPL.start

  c = Libvirt::Connection.new('qemu+tcp://localhost:16510/system')
  c.open
  res = c.set_keep_alive(2, 1)
  Libvirt.logger.info {  "set_keep_alive #{res}" }
  CONNS.push(c)

  puts "Connection version #{c.version.inspect}"
  puts "Connection lib_version #{c.lib_version.inspect}"
  puts "Connection hostname #{c.hostname.inspect}"
  puts "Connection max_vcpus #{c.max_vcpus.inspect}"
  puts "Connection capabilities #{c.capabilities.inspect}"
  node_info = c.node_info
  puts "Connection nodeInfo #{node_info}"
  puts "NodeInfo model #{node_info.model.inspect}"
  puts "NodeInfo cpus #{node_info.cpus.inspect}"
  puts "NodeInfo mhz #{node_info.mhz.inspect}"
  puts "NodeInfo nodes #{node_info.nodes.inspect}"
  puts "NodeInfo sockets #{node_info.sockets.inspect}"
  puts "NodeInfo cores #{node_info.cores.inspect}"
  puts "NodeInfo threads #{node_info.threads.inspect}"
  puts "NodeInfo memory #{node_info.memory.inspect}"

  cb_ids = Libvirt::Connection::DOMAIN_EVENT_IDS.map do |event_id|
    op = OpenStruct.new(a: 'b', event_id: event_id)
    callback_id = c.register_domain_event_callback(event_id, nil, op) do |conn, dom, *args, opaque|
      Libvirt.logger.info { "DOMAIN EVENT #{event_id} conn=#{conn}, dom=#{dom}, args=#{args}, opaque=#{opaque}" }
    end
    Libvirt.logger.info { "Registered domain event callback event_id=#{event_id} callback_id=#{callback_id}" }
    callback_id
  end
  CB_IDS.concat(cb_ids)

  puts "domains qty #{c.list_all_domains_qty}"

  domains = c.list_all_domains
  DOMS.concat(domains)
  puts "Domains (#{domains.size}): #{domains}"

  d = domains.first
  puts "Domain uuid #{d.uuid.inspect}"
  puts "Domain name #{d.name.inspect}"
  puts "Domain get_state #{d.get_state.inspect}"
  puts "Domain get_cpus #{d.max_vcpus.inspect}"
  puts "Domain max_memory #{d.max_memory.inspect}"
  puts "Domain xml_desc #{d.xml_desc.inspect}"

  # ASYNC_REACTOR.every(10) do
  #   LibvirtAsync::Util.create_task(nil, ASYNC_REACTOR) { IMPL.print_debug_info }.run
  # end

  ASYNC_REACTOR.every(5) do
    Libvirt.logger.info { "MEM USAGE: #{GetProcessMem.new.mb} MB" }
    # Libvirt.logger.info { "GC.start" }
    # GC.start
    # Libvirt.logger.info { "MEM USAGE: #{GetProcessMem.new.mb} MB" }
  end

  ASYNC_REACTOR.after(20) do
    Libvirt.logger.info { 'START Cleaning up!' }

    LibvirtAsync::Util.create_task(nil, ASYNC_REACTOR) do

      c = CONNS.first
      CB_IDS.each do |callback_id|
        Libvirt.logger.info { "Start retrieving callback_id=#{callback_id}" }
        opaque = c.deregister_domain_event_callback(callback_id)
        Libvirt.logger.info { "Retrieved opaque=#{opaque}" }
      end
      Libvirt.logger.info { 'Cleaning up!' }
      CONNS = []
      DOMS = []
      CB_IDS = []
      GC.start

    end.run
  end
end
