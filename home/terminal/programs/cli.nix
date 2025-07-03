{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    zip
    unzip

    libnotify
    ripgrep
    ripdrag
  ];

  programs = {
    ssh = {
      enable = true;
    };
  };
}
