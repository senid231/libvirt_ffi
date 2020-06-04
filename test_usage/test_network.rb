#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'libvirt'
require 'logger'
require 'active_support/all'
require 'async'
require 'json'

require_relative 'support/libvirt_async'
require_relative 'support/log_formatter'

require 'libvirt/xml'

Libvirt.logger = Logger.new(STDOUT, formatter: LogFormatter.new)
Libvirt.logger.level = ENV['DEBUG'] ? :debug : :info

IMPL = LibvirtAsync::Implementations.new

Async do
  ASYNC_REACTOR = Async::Task.current.reactor

  puts "Lib version #{Libvirt.lib_version}"
  puts "Gem version #{Libvirt::VERSION}"

  IMPL.start

  conn = Libvirt::Connection.new('qemu+tcp://localhost:16510/system')
  conn.open

  puts "Connection version #{conn.version.inspect}"
  puts "Connection lib_version #{conn.lib_version.inspect}"
  puts "Connection hostname #{conn.hostname.inspect}"

  networks = conn.list_all_networks
  puts "Connection networks qty #{networks.size}"

  networks.each.with_index do |network, i|
    puts "Network #{i} uuid=#{network.uuid}"
    puts "Network #{i} name=#{network.name}"
    puts "Network #{i} active?=#{network.active?}"
    puts "Network #{i} persistent?=#{network.persistent?}"
    puts "Network #{i} auto_start=#{network.auto_start?}"
    puts "Network #{i} bridge_name=#{network.bridge_name}"
    puts "Network #{i} xml_desc", network.xml_desc
    puts "Network #{i} xml", JSON.pretty_generate(Libvirt::Xml::Network.load(network.xml_desc).to_h)
  end

  networks.each.with_index do |network, i|
    dhcp_leases = network.dhcp_leases
    puts "Network #{i} DHCP Leases size=#{dhcp_leases.size}"

    dhcp_leases.each.with_index do |dhcp, j|
      puts "Network #{i} DHCP Lease #{j} name=#{dhcp.name}"
      puts "Network #{i} DHCP Lease #{j} iface=#{dhcp.iface}"
      puts "Network #{i} DHCP Lease #{j} expirytime=#{dhcp.expirytime}"
      puts "Network #{i} DHCP Lease #{j} type=#{dhcp.type}"
      puts "Network #{i} DHCP Lease #{j} mac=#{dhcp.mac}"
      puts "Network #{i} DHCP Lease #{j} iaid=#{dhcp.iaid}"
      puts "Network #{i} DHCP Lease #{j} ipaddr=#{dhcp.ipaddr}"
      puts "Network #{i} DHCP Lease #{j} prefix=#{dhcp.prefix}"
      puts "Network #{i} DHCP Lease #{j} hostname=#{dhcp.hostname}"
      puts "Network #{i} DHCP Lease #{j} clientid=#{dhcp.clientid}"
    end
  end

  puts 'register_network_event_callback'
  conn.register_network_event_callback(:LIFECYCLE) do |_c, net, event, detail, opaque|
    puts "NETWORK LIFECYCLE EVENT name=#{net.name}, event=#{event}, detail=#{detail}, opaque=#{opaque}"
  end

end
