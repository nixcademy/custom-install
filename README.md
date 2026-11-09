# custom-install

- Custom NixOS installer ISO (minimal installer + neovim/LSP setup + git)
- `nix run`: boot the ISO in a QEMU VM with a fresh empty 20G disk (installation demo)
- `nix build .#iso`: build the ISO, result in `result/iso/`
- files:
    - `configuration/default.nix`: installer config
    - `configuration/wifi.nix`: set your wifi SSID/password and your SSH public key (password ends up readable in the ISO and Nix store, demo only)
    - `configuration/vim.nix`: editor setup in the live system


## Flash to USB stick

Build image with `nix build` in this repo.

Check target device with `lsblk` or `dmesg` output and use this instead of the placeholder `/dev/sdX`:

```console
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
