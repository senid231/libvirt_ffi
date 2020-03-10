# frozen_string_literal: true

module Libvirt
  module Xml
    class StorageVolume < Generic
      # https://libvirt.org/formatstorage.html

      root_path './volume'

      attribute :type, type: :attr
      attribute :name
      attribute :key
      attribute :allocation, type: :memory
      attribute :capacity, type: :memory
      attribute :physical, type: :memory
      attribute :target_path, path: './target/path'
      attribute :target_format, type: :attr, name: :type, path: './target/format'
      attribute :target_perm_mode, path: './target/permissions/mode'
      attribute :target_perm_owner, path: './target/permissions/owner'
      attribute :target_perm_group, path: './target/permissions/group'
      attribute :target_perm_label, path: './target/permissions/label'
      attribute :timestamp_atime, path: './timestamp/atime'
      attribute :timestamp_btime, path: './timestamp/btime'
      attribute :timestamp_ctime, path: './timestamp/ctime'
      attribute :timestamp_mtime, path: './timestamp/mtime'
      attribute :compat
      # todo target/encryption target/nocow target/features
      # todo source
      # todo backingStore
    end
  end
end
