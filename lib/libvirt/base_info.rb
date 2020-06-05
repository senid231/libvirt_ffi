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

    # @param pointer [FFI::Pointer]
    def initialize(pointer)
      raise ArgumentError, "Can't initialize base class #{self.class}" if self.class == BaseInfo

      @ptr = pointer
      @struct = self.class._struct_class.new(pointer)
    end

    # @param attr [Symbol]
    # @return [Object, nil]
    def [](attr)
      @struct[attr]
    end

    # @return [Hash]
    def to_h
      @struct.members.map { |attr| [attr, @struct[attr]] }.to_h
    end

    def to_ptr
      @struct.to_ptr
    end
  end
end
