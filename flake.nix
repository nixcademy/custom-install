{
  description = "Custom NixOS installer ISO and a script to boot it in QEMU";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
    in
    {
      nixosConfigurations.installer = lib.nixosSystem {
        modules = [ ./configuration ];
      };

      packages = builtins.mapAttrs (system: pkgs: {
        iso =
          (inputs.self.nixosConfigurations.installer.extendModules {
            modules = [ { nixpkgs.hostPlatform = lib.mkForce system; } ];
          }).config.system.build.isoImage;

        nixos-vm = import ./vm-demo.nix {
          inherit pkgs;
          isoImage = inputs.self.packages.${system}.iso;
        };

        default = inputs.self.packages.${system}.iso;
      }) inputs.nixpkgs.legacyPackages;

      # Use `nix run` to boot VM and test/demonstrate installation manually
      apps = builtins.mapAttrs (system: pkgs: {
        default = {
          type = "app";
          program = lib.getExe inputs.self.packages.${system}.nixos-vm;
        };
      }) inputs.nixpkgs.legacyPackages;
    };
}
