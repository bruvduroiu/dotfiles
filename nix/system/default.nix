{ config, pkgs, ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./users.nix
  ];

  # Basic system packages
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    htop
    tree
    unzip
    firefox
  ];

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable X11 and desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable touchpad support
  services.xserver.libinput.enable = true;
}
