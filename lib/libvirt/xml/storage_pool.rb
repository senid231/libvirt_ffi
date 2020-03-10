# frozen_string_literal: true

module Libvirt
  module Xml
    class StoragePool < Generic
      # https://libvirt.org/formatstorage.html

      root_path './pool'

      attribute :type, type: :attr
      attribute :name
      attribute :uuid
      attribute :capacity, type: :memory
      attribute :allocation, type: :memory
      attribute :available, type: :memory
      attribute :target_path, path: './target/path'
      attribute :target_perm_mode, path: './target/permissions/mode'
      attribute :target_perm_owner, path: './target/permissions/owner'
      attribute :target_perm_group, path: './target/permissions/group'
      attribute :target_perm_label, path: './target/permissions/label'
      # todo source
    end
  end
end
