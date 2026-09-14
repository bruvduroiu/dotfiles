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

    # Screenshot/clipboard (Niri's screenshot helper is in the compositor module)
    wl-clipboard
    slurp
    grim
  ];
}
