{ modulesPath, pkgs, ... }:
{
  imports = [
    # standard nixos minimal installer config
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    # our customizations
    ./vim.nix
    ./wifi.nix
  ];

  environment.systemPackages = [
    pkgs.git
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
