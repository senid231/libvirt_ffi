# frozen_string_literal: true

module Libvirt
  module Xml
    class Graphics < Generic
      # https://libvirt.org/formatdomain.html#elementsGraphics

      attribute :type, type: :attr
      attribute :listen, type: :attr
      attribute :port, type: :attr
      attribute :auto_port, type: :attr, name: :autoport, cast: :bool
    end
  end
end
