# frozen_string_literal: true

require 'nokogiri'

module Libvirt
  module Xml
    class Generic
      class_attribute :_root_path, instance_writer: false, default: '.'
      class_attribute :_attributes_opts, instance_writer: false, default: {}

      def self.inherited(subclass)
        subclass._root_path = '.'
        subclass._attributes_opts = _attributes_opts.dup
      end

      def self.root_path(path)
        self._root_path = path
      end

      def self.attributes(*names)
        options = names.extract_options!
        names.each do |name|
          _attributes_opts.merge!(name.to_sym => options.dup)
        end
        attr_accessor(*names)
      end

      def self.attribute(name, options = {})
        _attributes_opts.merge!(name.to_sym => options.dup)
        attr_accessor name
      end

      # @param xml [String]
      # @return [Class<LibvirtXml::Generic>]
      def self.load(xml)
        xml_node = Nokogiri::XML(xml).xpath(_root_path).first
        new(xml_node)
      end

      # Build xml object with attributes.
      # @param attrs [Hash]
      # @return [Xml::Base]
      def self.build(attrs = {})
        xml_node = Nokogiri::XML(nil)
        obj = new(xml_node)
        attrs.each { |key, val| obj.public_send("#{key}=", val) }
        obj
      end

      # @param xml_node [Nokogiri::XML::Element]
      def initialize(xml_node)
        @xml_node = xml_node
        parse_xml_node
      end

      # @param attr [Symbol,String]
      # @return [Object,nil]
      def [](attr)
        read_attribute(attr)
      end

      # @param attr [Symbol,String]
      # @param value [Object,nil]
      # @return [Object,nil]
      def []=(attr, value)
        write_attribute(attr, value)
      end

      # @return [Hash{Symbol=>(Object,nil)}]
      def to_h
        _attributes_opts.map do |name, _opts|
          value = public_send(name)
          [name, serialize_for_hash(value)]
        end.to_h
      end

      # @return [String]
      def to_xml
        @xml_node.to_xml
      end

      delegate :as_json, :to_json, to: :to_h

      private

      def parse_xml_node
        _attributes_opts.each do |name, opts|
          value = parse_node(name, opts)
          value = decode(value, opts)
          write_attribute name, value
        end
      end

      # Parse node value using "parse_node_#{type}" method.
      # @param name [Symbol]
      # @param opts [Hash{Symbol=>Object}]
      # @return [Object, nil]
      def parse_node(name, opts)
        type = opts[:type] || :text
        meth = "parse_node_#{type}"


        if opts[:apply]
          opts[:apply].call(@xml_node, opts)
        elsif respond_to?(meth, true)
          send(meth, name, opts)
        else
          raise ArgumentError, "Invalid :type option #{type.inspect} for attribute #{name}"
        end
      end

      # Cast value using "decode_#{type}" method.
      # @param value [String]
      # @param opts [Hash{Symbol=>Object}]
      # @return [Object, nil]
      def decode(value, opts)
        return if value.nil?

        cast = opts[:cast]
        return value if cast.nil?
        meth = "decode_#{cast}"

        if opts[:array]
          value.map do |val|
            if cast.is_a?(Proc)
              cast.call(val, opts)
            elsif respond_to?(meth, true)
              send(meth, val, opts)
            else
              raise ArgumentError, "invalid :cast option #{cast.inspect}"
            end
          end
        end

        if cast.is_a?(Proc)
          cast.call(value, opts)
        elsif respond_to?(meth, true)
          send(meth, value, opts)
        else
          raise ArgumentError, "invalid :cast option #{cast.inspect}"
        end
      end

      # @param value [String, Boolean]
      # @return [Boolean]
      def decode_bool(value, _opts)
        return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        return true if value == 'yes'

        return false if value == 'no'

        nil
      end

      # @param value [String, Integer]
      # @return [Integer]
      # @raise [ArgumentError]
      def decode_int(value, _opts)
        Integer(value)
      end

      def find_nodes(name, opts)
        value_name = opts[:name]&.to_sym || name
        path = opts[:path] || "./#{value_name}"
        path == :root ? [@xml_node] : @xml_node.xpath(path)
      end

      def parse_node_text(name, opts)
        nodes = find_nodes(name, opts)

        if opts[:array]
          nodes.map(&:text)
        end

        node = nodes.first
        return if node.nil?
        node.text
      end

      def parse_node_attr(name, opts)
        nodes = find_nodes name, { path: :root }.merge(opts)
        value_name = opts[:name]&.to_sym || name

        if opts[:array]
          nodes.map { |node| node[value_name.to_s] }
        end

        node = nodes.first
        return if node.nil?
        node[value_name.to_s]
      end

      def parse_node_struct(name, opts)
        klass = opts[:class]
        raise ArgumentError, "Invalid :class option nil for attribute #{name}" if klass.nil?

        nodes = find_nodes(name, opts)

        if opts[:array]
          nodes.map { |node| klass.new(node) }
        end

        node = nodes.first
        return if node.nil?
        klass.new(node)
      end

      def parse_node_raw(name, opts)
        nodes = find_nodes(name, opts)

        if opts[:array]
          nodes.map { |node| node.to_xml }
        end

        node = nodes.first
        return if node.nil?
        node.to_xml
      end

      def parse_node_memory(name, opts)
        nodes = find_nodes(name, opts)

        if opts[:array]
          return [] if nodes.empty?

          nodes.map { |node| Util.parse_memory node.text, node['unit'] }
        end

        node = nodes.first
        return if node.nil?
        Util.parse_memory node.text, node['unit']
      end

      def read_attribute(attr)
        attr = attr.to_sym
        raise ArgumentError, "can't find attribute #{attr}" unless _attributes_opts.key?(attr)

        instance_variable_get :"@#{attr}"
      end

      def write_attribute(attr, value)
        attr = attr.to_sym
        raise ArgumentError, "can't find attribute #{attr}" unless _attributes_opts.key?(attr)

        instance_variable_set :"@#{attr}", value
      end

      def serialize_for_hash(value)
        return value.to_h if value.is_a?(Generic)
        return value.map { |val| serialize_for_hash(val) } if value.is_a?(Array)
        value
      end

    end
  end
end
