#!/usr/bin/env ruby

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

IMPL = LibvirtAsync::Implementations.new
CONNS = []
DOMS = []

Async do
  ASYNC_REACTOR = Async::Task.current.reactor

  IMPL.start

  c = Libvirt::Connection.new('qemu+tcp://localhost:16510/system')
  c.open
  res = c.set_keep_alive(2, 1)
  Libvirt.logger.info {  "set_keep_alive #{res}" }
  CONNS.push(c)

  c.register_domain_event_callback(Libvirt::DOMAIN_EVENT_ID_LIFECYCLE, nil) do |dom, event, detail, opaque|
    Libvirt.logger.info { "DOMAIN_EVENT_ID_LIFECYCLE user dom=#{dom}, event=#{event}, detail=#{detail}, opaque=#{opaque}" }
  end

  puts "domains qty #{c.list_all_domains_qty}"

  domains = c.list_all_domains
  DOMS.concat(domains)
  puts "Domains (#{domains.size}): #{domains}"

  domains.each_with_index do |domain, index|
    c.register_domain_event_callback(Libvirt::DOMAIN_EVENT_ID_LIFECYCLE, domain) do |dom, event, detail, opaque|
      Libvirt.logger.info { "DOMAIN_EVENT_CALLBACK LIFECYCLE user##{index} dom=#{dom}, event=#{event}, detail=#{detail}, opaque=#{opaque}" }
    end
  end

  res = domains.first.get_state
  Libvirt.logger.info { "Domain #{domains.first} state #{res}" }

  # ASYNC_REACTOR.every(10) do
  #   LibvirtAsync::Util.create_task(nil, ASYNC_REACTOR) { IMPL.print_debug_info }.run
  # end

  ASYNC_REACTOR.every(5) do
    Libvirt.logger.info { "MEM USAGE: #{GetProcessMem.new.mb} MB" }
    Libvirt.logger.info { "GC.start" }
    GC.start
    Libvirt.logger.info { "MEM USAGE: #{GetProcessMem.new.mb} MB" }
  end
end
