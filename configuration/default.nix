{ modulesPath, pkgs, ... }:
{
  imports = [
    # standard nixos minimal installer config
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    # our customizations
    ./vim.nix
    ./wifi.nix
    ./partition-format-mount.nix
  ];

  environment.systemPackages = [
    pkgs.git
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
