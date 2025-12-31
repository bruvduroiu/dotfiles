{ config, pkgs, lib, ... }:

{
  imports = [
    ./router.nix
    ./scripts.nix
  ];

  home = {
    username = "router";
    homeDirectory = "/home/router";
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Essential packages for travel router
  home.packages = with pkgs; [
    # Networking
    tailscale
    iptables
    nftables
    iproute2
    tcpdump
    nmap
    dnsutils
    curl
    wget

    # DNS filtering
    blocky

    # System tools
    htop
    tmux
    git
    jq
    rsync

    # For chroot management
    procps
    util-linux
  ];

  # Shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      router-start = "~/.local/bin/router-start";
      router-stop = "~/.local/bin/router-stop";
      router-status = "~/.local/bin/router-status";
      ts-status = "tailscale status";
      ll = "ls -la";
    };
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Bogdan";
    userEmail = "bogdan@example.com";
  };
}
