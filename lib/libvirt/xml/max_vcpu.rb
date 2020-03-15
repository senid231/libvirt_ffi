# frozen_string_literal: true

module Libvirt
  module Xml
    class MaxVcpu < Generic
      attribute :value, path: :root, cast: :int
      attribute :cpu_set, type: :attr, name: :cpuset
      attribute :current, type: :attr, cast: :int
      attribute :placement, type: :attr
    end
  end
end
