# frozen_string_literal: true

module Libvirt
  module Xml
    class Domain < Generic
      # https://libvirt.org/formatdomain.html

      root_path './domain'

      attribute :name
      attribute :uuid
      attribute :gen_id, path: './genid'
      attribute :title
      attribute :description
      attribute :metadata, type: :raw
      attribute :vcpu, type: :struct, class: MaxVcpu
      attribute :vcpus, type: :struct, array: true, class: Vcpu, cast: ->(objects, _) { objects.sort_by(&:id) }
      attribute :memory, type: :struct, class: Memory
      attribute :current_memory, type: :struct, class: Memory
      attribute :max_memory, type: :struct, class: Memory
      attribute :resource_partitions, path: './resource/partition', array: true
      attribute :on_power_off
      attribute :on_reboot
      attribute :on_crash
      attribute :on_lock_failure
      attribute :device_graphics, type: :struct, path: './devices/graphics', class: Graphics, array: true
      attribute :device_disks, type: :struct, path: './devices/disk', class: Disk, array: true
      # https://libvirt.org/formatdomain.html#elementsDevices
      # todo devices/emulator
      # todo devices/interface
      # todo devices/filesystem
      # todo devices/controller
      # todo devices/lease
      # todo devices/hostdev
      # todo devices/redirdev
      # todo devices/smartcard
      # todo devices/input
      # todo devices/hub
      # todo devices/video
      # todo devices/parallel
      # todo devices/serial
      # todo devices/console
      # todo devices/channel
      # todo devices/sound
      # todo devices/watchdog
      # todo devices/memballoon
      # todo devices/rng
      # todo devices/tpm
      # todo devices/nvram
      # todo devices/panic
      # todo devices/shmem
      # todo devices/memory
      # todo devices/iommu
      # todo devices/vsock
      # todo os
      # todo bootloader
      # todo bootloader_args
      # todo sysinfo
      # todo iothreads
      # todo iothreadids
      # todo cputune
      # todo memoryBacking
      # todo memtune
      # todo numatune
      # todo blkiotune
      # todo cpu
      # todo pm
      # todo features
      # todo clock
      # todo perf
      # todo seclabel
      # todo keywrap
      # todo launchSecurity
    end
  end
end
