#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'libvirt'
require 'logger'
require 'active_support/all'
require 'async'

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

  pools = conn.list_all_storage_pools
  puts "Connection storage pools qty #{pools.size}"

  pools.each.with_index do |pool, i|
    puts "Storage pool #{i} info", pool.info.to_h
    puts "Storage pool #{i} xml", Libvirt::Xml::StoragePool.load(pool.xml_desc).to_h
  end

  pools.each.with_index do |pool, i|
    volumes = pool.list_all_volumes
    puts "Storage pool #{i} volumes qty #{volumes.size}"

    volumes.each.with_index do |vol, j|
      puts "Storage pool #{i} volume #{j} info", vol.info.to_h
      puts "Storage pool #{i} volume #{j} xml", Libvirt::Xml::StorageVolume.load(vol.xml_desc).to_h
    end
  end
end
