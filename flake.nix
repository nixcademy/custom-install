{
  description = "Custom NixOS installer ISO and a script to boot it in QEMU";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

  outputs = inputs:
    let
      # change this to aarch64-linux if you are on an ARM system
      system = "x86_64-linux";

      inherit (inputs.nixpkgs) lib;
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      installer = inputs.self.nixosConfigurations.installer;
    in
    {
      nixosConfigurations.installer = lib.nixosSystem {
        modules = [
          ({ modulesPath, pkgs, ... }: {
            imports = [
              # standard nixos minimal installer config
              "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
              # our customizations
              ./vim.nix
              ./wifi.nix
            ];
            environment.systemPackages = [ pkgs.git ];
            nixpkgs.hostPlatform = system;
          })
        ];
      };

      packages.${system} = {
        iso = installer.config.system.build.isoImage;

        # Boots the installer with a fresh, empty 20G disk in the current directory
        run-vm = pkgs.writeShellScriptBin "run-vm" ''
          set -euo pipefail
          ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 disk.qcow2 20G
          install -m 644 ${pkgs.OVMF.variables} efivars.fd

          exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
            -machine q35,accel=kvm \
            -cpu host \
            -smp 4 \
            -m 4G \
            -drive if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.firmware} \
            -drive if=pflash,format=raw,file=efivars.fd \
            -drive if=virtio,format=qcow2,file=disk.qcow2 \
            -cdrom ${inputs.self.packages.${system}.iso}/iso/*.iso
            -nic user,model=virtio-net-pci \
            -device VGA,edid=on,xres=1280,yres=800 \
            -display gtk,show-cursor=on \
            "$@"
        '';

        default = inputs.self.packages.x86_64-linux.run-vm;
      };
    };
}
