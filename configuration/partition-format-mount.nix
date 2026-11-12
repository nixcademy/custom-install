{ pkgs, ... }:

let
  # The partitioning/formatting/mounting steps from the NixOS manual's
  # UEFI install guide: https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning
  partition-format-mount = pkgs.writeShellApplication {
    name = "partition-format-mount";
    text = ''
      disk=''${1:-/dev/vda}

      # /dev/nvme0n1 -> /dev/nvme0n1p1, /dev/vda -> /dev/vda1
      part=$disk
      if [[ "$disk" =~ [0-9]$ ]]; then part=''${disk}p; fi

      parted "$disk" -- mklabel gpt
      parted "$disk" -- mkpart root ext4 512MB -8GB
      parted "$disk" -- mkpart swap linux-swap -8GB 100%
      parted "$disk" -- mkpart ESP fat32 1MB 512MB
      parted "$disk" -- set 3 esp on
      udevadm settle

      mkfs.ext4 -F -L nixos "''${part}1"
      mkswap -L swap "''${part}2"
      swapon "''${part}2"
      mkfs.fat -F 32 -n boot "''${part}3"
      udevadm settle

      mount /dev/disk/by-label/nixos /mnt
      mkdir -p /mnt/boot
      mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

      nixos-generate-config --root /mnt
    '';
  };
in
{
  environment.systemPackages = [ partition-format-mount ];
}
