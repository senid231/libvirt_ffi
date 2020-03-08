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
    hv: nil,
    domains: [],
    cb_ids: []
}

Async do
  ASYNC_REACTOR = Async::Task.current.reactor

  puts "Lib version #{Libvirt.lib_version}"
  puts "Gem version #{Libvirt::VERSION}"

  IMPL.start

  OBJECTS[:hv] = Libvirt::Connection.new('qemu+tcp://localhost:16510/system')
  OBJECTS[:hv].open
  res = OBJECTS[:hv].set_keep_alive(2, 1)
  Libvirt.logger.info {  "set_keep_alive #{res}" }

  puts "Connection version #{OBJECTS[:hv].version.inspect}"
  puts "Connection lib_version #{OBJECTS[:hv].lib_version.inspect}"
  puts "Connection hostname #{OBJECTS[:hv].hostname.inspect}"
  puts "Connection max_vcpus #{OBJECTS[:hv].max_vcpus.inspect}"
  puts "Connection capabilities #{OBJECTS[:hv].capabilities.inspect}"
  node_info = OBJECTS[:hv].node_info
  puts "Connection nodeInfo #{node_info}"
  puts "NodeInfo model #{node_info.model.inspect}"
  puts "NodeInfo cpus #{node_info.cpus.inspect}"
  puts "NodeInfo mhz #{node_info.mhz.inspect}"
  puts "NodeInfo nodes #{node_info.nodes.inspect}"
  puts "NodeInfo sockets #{node_info.sockets.inspect}"
  puts "NodeInfo cores #{node_info.cores.inspect}"
  puts "NodeInfo threads #{node_info.threads.inspect}"
  puts "NodeInfo memory #{node_info.memory.inspect}"

  Libvirt::Connection::DOMAIN_EVENT_IDS.map do |event_id|
    op = OpenStruct.new(a: 'b', event_id: event_id)
    callback_id = OBJECTS[:hv].register_domain_event_callback(event_id, nil, op) do |conn, dom, *args, opaque|
      Libvirt.logger.info { "DOMAIN EVENT #{event_id} conn=#{conn}, dom=#{dom}, args=#{args}, opaque=#{opaque}" }
    end
    Libvirt.logger.info { "Registered domain event callback event_id=#{event_id} callback_id=#{callback_id}" }
    OBJECTS[:cb_ids] << callback_id
  end

  puts "domains qty #{OBJECTS[:hv].list_all_domains_qty}"

  OBJECTS[:domains] = OBJECTS[:hv].list_all_domains
  puts "Domains (#{OBJECTS[:domains].size}): #{OBJECTS[:domains]}"

  d = OBJECTS[:domains].first
  puts "Domain uuid #{d.uuid.inspect}"
  puts "Domain name #{d.name.inspect}"
  puts "Domain get_state #{d.get_state.inspect}"
  puts "Domain get_cpus #{d.max_vcpus.inspect}"
  puts "Domain max_memory #{d.max_memory.inspect}"
  # puts "Domain xml_desc #{d.xml_desc.inspect}"

  # ASYNC_REACTOR.every(10) do
  #   LibvirtAsync::Util.create_task(nil, ASYNC_REACTOR) { IMPL.print_debug_info }.run
  # end

  ASYNC_REACTOR.every(5) do
    Libvirt.logger.info { "MEM USAGE: #{GetProcessMem.new.mb} MB" }
    # Libvirt.logger.info { "GC.start" }
    # GC.start
    # Libvirt.logger.info { "MEM USAGE: #{GetProcessMem.new.mb} MB" }
  end

  # ASYNC_REACTOR.after(20) do
  #   Libvirt.logger.info { 'START Cleaning up!' }
  #
  #   LibvirtAsync::Util.create_task(nil, ASYNC_REACTOR) do
  #
  #     OBJECTS[:cb_ids].each do |callback_id|
  #       Libvirt.logger.info { "Start retrieving callback_id=#{callback_id}" }
  #       opaque = OBJECTS[:hv].deregister_domain_event_callback(callback_id)
  #       Libvirt.logger.info { "Retrieved opaque=#{opaque}" }
  #     end
  #     Libvirt.logger.info { 'Cleaning up!' }
  #     OBJECTS[:hv] = nil
  #     OBJECTS[:domains] = []
  #     OBJECTS[:cb_ids] = []
  #     Libvirt.logger.info { "GC.start 1" }
  #     GC.start
  #
  #     ASYNC_REACTOR << LibvirtAsync::Util.create_task(nil, ASYNC_REACTOR) do
  #       Libvirt.logger.info { "GC.start 2" }
  #       GC.start
  #     end.fiber
  #
  #   end.run
  # end

  # puts 'undefine DOM'
  # d.undefine
  # ASYNC_REACTOR.sleep 5

  # begin
  #   puts 'DOM starting...'
  #   d.start
  #   puts 'DOM started'
  # rescue Libvirt::Errors::LibError => e
  #   STDERR.puts "error starting\n#{e.class}\n#{e.message}", e.error_data
  # end
  #
  # ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state} before save_memory"
  # d.save_memory
  # puts "DOMAIN state #{d.get_state} after save_memory"
  #
  # ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state} before start"
  # d.start
  # puts "DOMAIN state #{d.get_state} after start"
  #
  # #ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state} before resume"
  # d.resume
  # puts "DOMAIN state #{d.get_state} after resume"

  # ASYNC_REACTOR.sleep 10
  # puts "DOMAIN state #{d.get_state} before shutdown"
  # d.shutdown(1)
  # puts "DOMAIN state #{d.get_state} after shutdown"
  #
  # ASYNC_REACTOR.sleep 10
  # puts "DOMAIN state #{d.get_state}"
  # d.start
  # puts 'DOM start'
  #
  # ASYNC_REACTOR.sleep 10
  # puts "DOMAIN state #{d.get_state}"
  # d.reboot
  # puts 'DOM reboot'
  #
  # ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state}"
  # d.suspend
  # puts 'DOM suspend'
  #
  # ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state}"
  # d.resume
  # puts 'DOM resume'
  #
  # ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state}"
  # d.reset
  # puts 'DOM reset'
  #
  # ASYNC_REACTOR.sleep 5
  # puts "DOMAIN state #{d.get_state}"
  # d.power_off
  # puts 'DOM power_off'
  #
  # ASYNC_REACTOR.sleep 5
  # d.start
  # puts 'DOM start'

end
