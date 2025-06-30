{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    zip
    unzip

    libnotify
    ripgrep
  ];

  programs = {
    ssh = {
      enable = true;
    };
  };
}
