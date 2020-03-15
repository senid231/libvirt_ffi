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

  doms = conn.list_all_domains
  puts "Connection domains qty #{doms.size}"

  doms.each.with_index do |dom, i|
    puts "Domain #{i} xml", dom.xml_desc
    puts "Domain #{i} xml object", Libvirt::Xml::Domain.load(dom.xml_desc).to_h
  end

end
