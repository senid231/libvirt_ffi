# frozen_string_literal: true

module Libvirt
  class BaseInfo
    # Abstract Base class for info

    class << self
      attr_accessor :_struct_class

      # @param [Class<FFI::Struct>]
      def struct_class(klass)
        self._struct_class = klass
        klass.members.each do |attr|
          define_method(attr) { @struct[attr] }
        end
      end
    end

    def initialize(pointer)
      raise ArgumentError, "Can't initialize base class #{self.class}" if self.class == BaseInfo

      @ptr = pointer
      @struct = self.class._struct_class.new(pointer)
    end

    def [](attr)
      @struct[attr]
    end

    def to_h
      @struct.members.map { |attr| [attr, @struct[attr]] }.to_h
    end
  end
end
