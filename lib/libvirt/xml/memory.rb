# frozen_string_literal: true

module Libvirt
  module Xml
    class Memory < Generic
      attribute :dump_core, type: :attr, name: :dumpCore
      attribute :slots, type: :attr

      attribute :bytes, apply: ->(node, _opts) do
        Util.parse_memory node.text, node['unit']
      end
    end
  end
end
