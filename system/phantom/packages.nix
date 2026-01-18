# Phantom USB - Additional packages for portable hacking station
{ config, lib, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Disk management
    parted
    gparted
    ntfs3g

    # Network tools
    nmap
    tcpdump
    wireguard-tools

    # System monitoring
    htop
    btop
    iotop
    lsof

    # USB/hardware tools
    usbutils
    pciutils
    lshw

    # Screenshot/clipboard (Hyprland)
    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
    wl-clipboard
    slurp
    grim
  ];
}
