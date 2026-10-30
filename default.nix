# Builds `nixos-vm`: a script that boots the minimal NixOS installer ISO in
# QEMU/KVM (UEFI) with a fresh, empty 20G disk to install onto.
#
#   nix-build && ./result/bin/nixos-vm           # fresh disk, boot installer
#   ./result/bin/nixos-vm --keep                 # reuse disk, boot installed system
#
# Tunables (env vars): VM_DIR (./nixos-vm), VM_MEM (4G), VM_CPUS (4),
# VM_DISK_SIZE (20G), VM_RES (1280x800), VM_DISPLAY (gtk,...).
# Extra arguments are passed through to qemu.
#
# nixpkgs is pinned with nixtamal: `nixtamal refresh` to update.
{
  system ? builtins.currentSystem,
  pkgs ? import (import ./nix/tamal { }).nixpkgs { inherit system; },
}:

let
  installer = pkgs.nixos [
    ({ modulesPath, ... }: {
      imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
    })
    ./vim.nix
    ./wifi.nix
    {
      environment.systemPackages = [ pkgs.git ];
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
  isoImage = installer.config.system.build.isoImage;
in
pkgs.writeShellApplication {
  name = "nixos-vm";
  runtimeInputs = [ pkgs.qemu_kvm ];
  text = ''
    VM_DIR=''${VM_DIR:-./nixos-vm}
    VM_MEM=''${VM_MEM:-4G}
    VM_CPUS=''${VM_CPUS:-4}
    VM_DISK_SIZE=''${VM_DISK_SIZE:-20G}
    VM_RES=''${VM_RES:-1280x800}
    VM_DISPLAY=''${VM_DISPLAY:-gtk,zoom-to-fit=off,show-menubar=off,show-cursor=on}

    disk="$VM_DIR/disk.qcow2"
    efivars="$VM_DIR/efivars.fd"
    iso=(${isoImage}/iso/*.iso)

    keep=false
    if [[ "''${1:-}" == "--keep" ]]; then keep=true; shift; fi

    mkdir -p "$VM_DIR"
    if ! $keep || [[ ! -e "$disk" ]]; then
      # Fresh disk + fresh EFI NVRAM (boot entries live there, so they belong together)
      rm -f "$disk" "$efivars"
      qemu-img create -q -f qcow2 "$disk" "$VM_DISK_SIZE"
      install -m 644 ${pkgs.OVMF.variables} "$efivars"
    fi

    # The disk boots first; while it's still empty, OVMF falls through to the ISO.
    # VGA (not virtio-vga): both OVMF and Linux pick up its EDID resolution.
    exec qemu-system-x86_64 \
      -name nixos-vm \
      -machine q35,accel=kvm,vmport=off \
      -cpu host \
      -smp "$VM_CPUS" \
      -m "$VM_MEM" \
      -drive if=pflash,format=raw,unit=0,readonly=on,file=${pkgs.OVMF.firmware} \
      -drive if=pflash,format=raw,unit=1,file="$efivars" \
      -object iothread,id=io0 \
      -drive if=none,id=disk0,file="$disk",format=qcow2,cache=none,aio=io_uring,discard=unmap,detect-zeroes=unmap \
      -device virtio-blk-pci,drive=disk0,iothread=io0,bootindex=0 \
      -drive if=none,id=cd0,file="''${iso[0]}",media=cdrom,readonly=on \
      -device ide-cd,drive=cd0,bootindex=1 \
      -nic user,model=virtio-net-pci \
      -device virtio-rng-pci \
      -device virtio-balloon-pci,free-page-reporting=on \
      -device VGA,edid=on,xres="''${VM_RES%x*}",yres="''${VM_RES#*x}",vgamem_mb=32 \
      -display "$VM_DISPLAY" \
      -device qemu-xhci \
      -device usb-tablet \
      "$@"
  '';
}
