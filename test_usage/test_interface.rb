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

  interfaces = conn.list_all_interfaces
  puts "Connection interfaces qty #{interfaces.size}"

  interfaces.each.with_index do |interface, i|
    puts "Interface #{i} name=#{interface.name}"
    puts "Interface #{i} active?=#{interface.active?}"
    puts "Interface #{i} mac=#{interface.mac}"
    puts "Interface #{i} xml_desc", interface.xml_desc
    puts "Interface #{i} xml", JSON.pretty_generate(Libvirt::Xml::Interface.load(interface.xml_desc).to_h)
  end

end
