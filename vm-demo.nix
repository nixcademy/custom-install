# reusing qemu-common.nix to pick qemu binary, machine and accel for guest arch
{ pkgs, isoImage }:

let
  qemu-common = import "${pkgs.path}/nixos/lib/qemu-common.nix" { inherit (pkgs) lib stdenv; };
in

pkgs.writeShellApplication {
  name = "nixos-vm";
  runtimeInputs = [ pkgs.qemu_kvm ];
  text = ''
    set -euo pipefail

    disk=nixos-vm/disk.qcow2
    efivars=nixos-vm/efivars.fd
    iso=(${isoImage}/iso/*.iso)

    keep=false
    if [[ "''${1:-}" == "--keep" ]]; then keep=true; shift; fi

    mkdir -p nixos-vm
    if ! $keep || [[ ! -e "$disk" ]]; then
      rm -f "$disk" "$efivars"
      qemu-img create -q -f qcow2 "$disk" 40G
      install -m 644 ${pkgs.OVMF.variables} "$efivars"
    fi

    exec ${qemu-common.qemuBinary pkgs.qemu_kvm} \
      -name nixos-vm \
      -smp 4 \
      -m 4G \
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
      -device VGA,edid=on,xres=1280,yres=800,vgamem_mb=32 \
      -display gtk,zoom-to-fit=off,show-menubar=off,show-cursor=on \
      -device qemu-xhci \
      -device usb-tablet \
      "$@"
  '';
}
