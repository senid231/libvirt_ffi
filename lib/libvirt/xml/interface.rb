# frozen_string_literal: true

module Libvirt
  module Xml
    class Interface < Generic
      # no official doc found
      #
      # <interface type='ethernet' name='lo'>
      #   <protocol family='ipv4'>
      #     <ip address='127.0.0.1' prefix='8'/>
      #   </protocol>
      #   <protocol family='ipv6'>
      #     <ip address='::1' prefix='128'/>
      #   </protocol>
      #   <link state='unknown'/>
      # </interface>
      #
      # <interface type='bridge'>
      #   <mac address='52:54:00:4f:7e:b2'/>
      #   <source bridge='vbr107'/>
      #   <target dev='vnet4'/>
      #   <model type='virtio'/>
      #   <alias name='net0'/>
      #   <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
      # </interface>

      root_path './interface'

      attribute :type, type: :attr

      attribute :name, type: :attr
      attribute :link_state, type: :attr, path: './link', name: 'state'
      attribute :ip_addresses, type: :ip_addresses

      attribute :mac_address, type: :attr, path: './mac', name: 'address'
      attribute :source_bridge, type: :attr, path: './source', name: 'bridge'
      attribute :target_dev, type: :attr, path: './target', name: 'dev'
      attribute :model_type, type: :attr, path: './model', name: 'type'
      attribute :alias_names, type: :attr, path: './alias', name: 'name', array: true
      attribute :addresses, type: :addresses

      private

      def parse_node_addresses(_, _opts)
        nodes = find_nodes(nil, path: './address')

        nodes.map do |node|
          {
              type: node['type'],
              domain: node['domain'],
              bus: node['bus'],
              slot: node['slot'],
              function: node['function']
          }
        end
      end

      def parse_node_ip_addresses(_, _opts)
        protocols = find_nodes(nil, path: './protocol')
        ip_addresses = []

        protocols.each do |protocol|
          family = protocol['family']

          protocol.xpath('./ip').each do |ip|
            # ip['netmask'], ip['localPtr']
            ip_addresses.push(
                address: ip['address'],
                prefix: ip['prefix'],
                family: family
            )
          end
        end

        ip_addresses
      end
    end
  end
end
