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
    require 'libvirt/xml/storage_pool'
    require 'libvirt/xml/storage_volume'
  end
end
