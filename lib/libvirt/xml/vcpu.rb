# frozen_string_literal: true

module Libvirt
  module Xml
    class Vcpu < Generic
      attribute :id, type: :attr, cast: :int
      attribute :enabled, type: :attr, cast: :bool
      attribute :hot_pluggable, type: :attr, cast: :bool, name: :hotpluggable
      attribute :order, type: :attr, cast: :int
    end
  end
end
