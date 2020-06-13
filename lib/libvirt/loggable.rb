# frozen_string_literal: true

module Libvirt
  module Loggable
    # caller[0].match(/`(.*)'/)[1]

    module ClassMethods
      def dbg(prog_name = nil, &block)
        return if Libvirt.logger.nil?

        if prog_name.nil?
          meth = caller[0].match(/`(.*)'/)[1]
          meth = "<#{meth}>" if meth.include?(' ')
          prog_name = "#{name}.#{meth}"
        end
        Libvirt.logger.debug(prog_name, &block)
      end

      def err(prog_name = nil, &block)
        return if Libvirt.logger.nil?

        if prog_name.nil?
          meth = caller[0].match(/`(.*)'/)[1]
          meth = "<#{meth}>" if meth.include?(' ')
          prog_name = "#{name}.#{meth}"
        end
        Libvirt.logger.error(prog_name, &block)
      end
    end

    def self.included(base)
      base.extend ClassMethods
      super
    end

    def dbg(prog_name = nil, &block)
      return if Libvirt.logger.nil?

      if prog_name.nil?
        meth = caller[0].match(/`(.*)'/)[1]
        meth = "<#{meth}>" if meth.include?(' ')
        prog_name = "#{self.class.name}##{meth}"
      end
      Libvirt.logger.debug(prog_name, &block)
    end

    def err(prog_name = nil, &block)
      return if Libvirt.logger.nil?

      if prog_name.nil?
        meth = caller[0].match(/`(.*)'/)[1]
        meth = "<#{meth}>" if meth.include?(' ')
        prog_name = "#{self.class.name}##{meth}"
      end
      Libvirt.logger.error(prog_name, &block)
    end
  end
end
