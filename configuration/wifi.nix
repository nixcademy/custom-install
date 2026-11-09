{
  # Connect to the home wifi at boot. Demo only: the password ends up
  # world-readable on the ISO and in the Nix store.
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles.home-wifi = {
    connection = {
      id = "home-wifi";
      type = "wifi";
      autoconnect = true;
    };
    wifi = {
      ssid = "MyHomeNetwork"; # your wifi SSID here
      mode = "infrastructure";
    };
    wifi-security = {
      key-mgmt = "wpa-psk";
      psk = "my-home-password"; # your wifi password here
    };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };

  # add your SSH key here. Laptops will pop up in your network and you can
  # install via root shell or use nixos-anywhere.
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDu77nd6FXzaJCbaVSzD/3OUhfixGwFR1C79Oqt3H03U demo@example.com"
  ];
}
