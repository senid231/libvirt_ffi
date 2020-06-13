# frozen_string_literal: true

require 'nokogiri'
require 'libvirt/util'

module Libvirt
  module Xml
    # https://libvirt.org/format.html
    # namespace for libvirt xml objects.
    # does not loaded by default.
    # requires nokogiri.

    require 'libvirt/xml/generic'
    require 'libvirt/xml/memory'
    require 'libvirt/xml/graphics'
    require 'libvirt/xml/disk'
    require 'libvirt/xml/max_vcpu'
    require 'libvirt/xml/vcpu'
    require 'libvirt/xml/ip_address'
    require 'libvirt/xml/device_address'
    require 'libvirt/xml/storage_pool'
    require 'libvirt/xml/storage_volume'
    require 'libvirt/xml/network'
    require 'libvirt/xml/interface'
    require 'libvirt/xml/domain'
  end
end
