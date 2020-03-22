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

STDOUT.sync = true
STDERR.sync = true

def log_error(error, skip_backtrace: false, causes: [])
  STDERR.puts "<#{error.class}>: #{error.message}", error.backtrace
  if error.cause && error.cause != error && !causes.include?(error.cause)
    causes.push(error)
    log_error(error.cause, skip_backtrace: skip_backtrace, causes: causes)
  end
end

def libvirt_safe(rescue_value = nil)
  yield
rescue Libvirt::Errors::LibError => e
  STDERR.puts "<#{e.class}>: #{e.message}"
  rescue_value
end

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

  dom = conn.list_all_domains.first
  puts "Domain #{dom.uuid} #{dom.name}"

  libvirt_safe do
    dom.start
  end

  dom.set_metadata("test title #{Process.pid}", type: :TITLE, flags: :AFFECT_CONFIG)
  dom.set_metadata("test desc #{Process.pid}", type: :DESCRIPTION, flags: :AFFECT_CONFIG)

  puts "domain title", libvirt_safe{ dom.get_metadata(type: :TITLE, flags: :AFFECT_CONFIG) }
  puts "domain description", libvirt_safe { dom.get_metadata(type: :DESCRIPTION, flags: :AFFECT_CONFIG) }

  puts "full XML title", Libvirt::Xml::Domain.load(dom.xml_desc).title
  puts "full XML description", Libvirt::Xml::Domain.load(dom.xml_desc).description

  namespace = 'https://example.com'
  old_metadata = dom.get_metadata(
      uri: namespace, flags: :AFFECT_CONFIG
  )

  puts "Old Metadata", old_metadata

  new_metadata = "<pid>#{Process.pid}</pid>"
  key = 'example'
  dom.set_metadata new_metadata,
                   key: key,
                   uri: namespace,
                   flags: :AFFECT_CONFIG

  puts "new metadata", dom.get_metadata(
      uri: namespace, flags: :AFFECT_CONFIG
  )

  puts "full XML metadata", Libvirt::Xml::Domain.load(dom.xml_desc).metadata

  puts "domain shutdown", libvirt_safe { dom.shutdown }
  ASYNC_REACTOR.sleep 5
  puts dom.get_state

  puts "domain start", libvirt_safe { dom.start }
  ASYNC_REACTOR.sleep 2
  puts dom.get_state

  puts "full XML metadata", Libvirt::Xml::Domain.load(dom.xml_desc).metadata
  puts "full XML title", Libvirt::Xml::Domain.load(dom.xml_desc).title
  puts "full XML description", Libvirt::Xml::Domain.load(dom.xml_desc).description

rescue StandardError => e
  log_error(e)
  exit 1
end
