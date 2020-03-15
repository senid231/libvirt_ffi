# frozen_string_literal: true

module Libvirt
  module Xml
    class Disk < Generic
      # https://libvirt.org/formatdomain.html#elementsDisks

      attribute :type, type: :attr
      attribute :device, type: :attr
      attribute :model, type: :attr
      attribute :raw_io, type: :attr, name: :rawio, cast: :bool
      attribute :sg_io, type: :attr, name: :sgio
      attribute :snapshot, type: :attr
      attribute :source_file, name: :file, path: './source', type: :attr
      attribute :source_dev, name: :dev, path: './source', type: :attr
      attribute :source_dir, name: :dir, path: './source', type: :attr
      attribute :source_protocol, name: :protocol, path: './source', type: :attr
      attribute :source_pool, name: :pool, path: './source', type: :attr
      attribute :source_volume, name: :volume, path: './source', type: :attr
      attribute :source_mode, name: :mode, path: './source', type: :attr
      attribute :source_name, name: :name, path: './source', type: :attr
      attribute :source_type, name: :type, path: './source', type: :attr
      attribute :source_managed, name: :managed, path: './source', type: :attr, cast: :bool
      attribute :source_namespace, name: :namespace, path: './source', type: :attr
      attribute :source_index, name: :index, path: './source', type: :attr
      attribute :source_host_name, name: :name, path: './source/host', type: :attr
      attribute :source_host_port, name: :port, path: './source/host', type: :attr
      attribute :source_host_transport, name: :transport, path: './source/host', type: :attr
      attribute :source_host_socket, name: :socket, path: './source/host', type: :attr
      attribute :source_snapshot_name, name: :name, path: './source/snapshot', type: :attr
      attribute :source_config_file, name: :file, path: './source/config', type: :attr
      # TODO: source/auth
      # TODO: source/encryption
      # TODO: source/reservations
      # TODO: source/initiator
      # TODO: source/address
      # TODO: source/slices
      # TODO: backingStore
      # TODO: mirror
      # TODO: target
      # TODO: iotune
      # TODO: driver
      # TODO: backenddomain
      # TODO: boot
      # TODO: encryption
      # TODO: readonly
      # TODO: shareable
      # TODO: transient
      # TODO: serial
      # TODO: wwn
      # TODO: vendor
      # TODO: product
      # TODO: address
      # TODO: auth
      # TODO: geometry
      # TODO: blockio
    end
  end
end
