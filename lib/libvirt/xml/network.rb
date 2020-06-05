# frozen_string_literal: true

module Libvirt
  module Xml
    class Network < Generic
      # https://libvirt.org/formatnetwork.html

      root_path './network'

      # <network ipv6='yes' trustGuestRxFilters='no'>
      #   ...
      attribute :ipv6, type: :attr, cast: :bool, default: false

      attribute :trust_guest_rx_filters,
                type: :attr,
                name: 'trustGuestRxFilters',
                cast: :bool,
                default: false

      # <name>default</name>
      # <uuid>3e3fce45-4f53-4fa7-bb32-11f34168b82b</uuid>
      attribute :name
      attribute :uuid

      # <metadata>
      #   <app1:foo xmlns:app1="http://app1.org/app1/">..</app1:foo>
      #   <app2:bar xmlns:app2="http://app1.org/app2/">..</app2:bar>
      # </metadata>
      attribute :metadata, type: :raw

      # <bridge name="virbr0" stp="on" delay="5" macTableManager="libvirt"/>
      attribute :bridge_name,
                type: :attr,
                name: 'name',
                path: './bridge'

      attribute :bridge_stp,
                type: :attr,
                name: 'stp',
                cast: :bool,
                path: './bridge'

      attribute :bridge_delay,
                type: :attr,
                name: 'delay',
                cast: :int,
                path: './bridge'

      attribute :bridge_mac_table_manager,
                type: :attr,
                name: 'macTableManager',
                path: './bridge'

      # <mtu size="9000"/>
      attribute :mtu_size, type: :attr, path: './mtu', name: 'size', cast: :int

      # <domain name="example.com" localOnly="no"/>
      attribute :domain_name, type: :attr, path: './domain', name: 'name'
      attribute :domain_local_only, type: :attr, path: './domain', name: 'localOnly', cast: :bool

      # <forward mode='nat' dev='eth0'>
      #     <nat>
      #       <address start='1.2.3.4' end='1.2.3.10'/>
      #     </nat>
      #   </forward>
      attribute :forward_mode, type: :attr, path: './forward', name: 'mode'
      attribute :forward_dev, type: :attr, path: './forward', name: 'dev'
      attribute :forward_nat_address, type: :forward_nat, node_name: :address
      attribute :forward_nat_port, type: :forward_nat, node_name: :port

      # <forward mode='passthrough'>
      #   <interface dev='eth10'/>
      #   <interface dev='eth11'/>
      #   <interface dev='eth12'/>
      #   <interface dev='eth13'/>
      #   <interface dev='eth14'/>
      # </forward>
      attribute :forward_interfaces,
                type: :attr,
                path: './forward/interface',
                name: 'dev',
                array: true

      # <forward mode='passthrough'>
      #   <pf dev='eth0'/>
      # </forward>
      attribute :forward_pf,
                type: :attr,
                path: './forward/pf',
                name: 'dev',
                array: true

      # <forward mode='hostdev' managed='yes'>
      #     <driver name='vfio'/>
      #     <address type='pci' domain='0' bus='4' slot='0' function='1'/>
      #     <address type='pci' domain='0' bus='4' slot='0' function='2'/>
      #     <address type='pci' domain='0' bus='4' slot='0' function='3'/>
      #   </forward>
      attribute :forward_manager,
                type: :attr,
                path: './forward',
                name: 'managed',
                cast: :bool,
                default: false

      attribute :forward_driver,
                type: :attr,
                path: './forward/driver',
                name: 'name'

      attribute :forward_addresses, type: :forward_hostdev_address

      attribute :mac_address,
                type: :attr,
                path: './mac',
                name: 'address'

      # <dns>
      #   <txt name="example" value="example value"/>
      #   <forwarder addr="8.8.8.8"/>
      #   <forwarder domain='example.com' addr="8.8.4.4"/>
      #   <forwarder domain='www.example.com'/>
      #   <srv service='name' protocol='tcp' domain='test-domain-name' target='.'
      #     port='1024' priority='10' weight='10'/>
      #   <host ip='192.168.122.2'>
      #     <hostname>myhost</hostname>
      #     <hostname>myhostalias</hostname>
      #   </host>
      # </dns>
      attribute :dns_forwarder, type: :dns_forwarder
      attribute :dns_txt, type: :dns_txt
      attribute :dns_host_ip, type: :attr, path: './dns/host', name: 'ip'
      attribute :dns_hostnames, path: './dns/host/hostname', array: true
      attribute :dns_srv, type: :dns_txt

      attribute :ip_addresses, type: :struct, path: './ip', class: IpAddress, array: true

      # https://libvirt.org/formatnetwork.html#elementQoS
      # TODO continue from <bandwidth>

      private

      def parse_node_forward_nat(_, opts)
        nodes = find_nodes(nil, path: "./forward/nat/#{opts[:node_name]}")

        nodes.map do |node|
          [node['start'], node['stop']]
        end
      end

      def parse_node_forward_hostdev_address(_, _opts)
        nodes = find_nodes(nil, path: './forward/address')

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

      def parse_node_dns_forwarder(_, _opts)
        nodes = find_nodes(nil, path: './dns/forwarder')

        nodes.map do |node|
          {
              domain: node['domain'],
              addr: node['addr']
          }
        end
      end

      def parse_node_dns_txt(_, _opts)
        nodes = find_nodes(nil, path: './dns/txt')

        nodes.map do |node|
          {
              name: node['name'],
              value: node['value']
          }
        end
      end

      def parse_node_dns_srv(_, _opts)
        nodes = find_nodes(nil, path: './dns/srv')

        nodes.map do |node|
          {
              name: node['name'],
              protocol: node['protocol'],
              target: node['target'],
              port: node['port'],
              priority: node['priority'],
              weight: node['weight'],
              domain: node['domain']
          }
        end
      end
    end
  end
end
