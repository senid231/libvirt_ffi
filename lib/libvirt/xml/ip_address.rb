# frozen_string_literal: true

module Libvirt
  module Xml
    class IpAddress < Generic
      # https://libvirt.org/formatnetwork.html#elementsAddress

      # <ip address="192.168.122.1" netmask="255.255.255.0" localPtr="yes">
      #   <dhcp>
      #     <range start="192.168.122.100" end="192.168.122.254"/>
      #     <host mac="00:16:3e:77:e2:ed" name="foo.example.com" ip="192.168.122.10"/>
      #     <host mac="00:16:3e:3e:a9:1a" name="bar.example.com" ip="192.168.122.11"/>
      #   </dhcp>
      # </ip>
      # <ip family="ipv6" address="2001:db8:ca2:2::1" prefix="64" localPtr="yes"/>
      attribute :address, type: :attr
      attribute :netmask, type: :attr
      attribute :prefix, type: :attr
      attribute :local_ptr, type: :attr, name: 'localPtr', cast: :bool, default: false
      attribute :family, type: :attr, default: 'ipv4'
      attribute :tftp_root, type: :attr, path: './tftp', name: 'root'
      attribute :dhcp_ranges, type: :dhcp_ranges
      attribute :dhcp_hosts, type: :dhcp_hosts
      attribute :dhcp_bootp_file, type: :attr, path: './dhcp/bootp', name: 'file'
      attribute :dhcp_bootp_server, type: :attr, path: './dhcp/bootp', name: 'server'

      private

      def parse_node_dhcp_ranges(_, _opts)
        nodes = find_nodes(nil, path: './dhcp/range')

        nodes.map do |node|
          [node['start'], node['end']]
        end
      end

      def parse_node_dhcp_hosts(_, _opts)
        nodes = find_nodes(nil, path: './dhcp/host')

        nodes.map do |node|
          {
              mac: node['mac'],
              ip: node['ip'],
              name: node['name'],
              host: node['host']
          }
        end
      end
    end
  end
end
