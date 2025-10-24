{ pkgs, ... }:

{
  imports = [
    ./aws.nix
    ./bat.nix
    ./btop.nix
    ./claude
    ./cli.nix
    ./crush.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./gdu.nix
    ./git.nix
    ./k9s.nix
    ./opencode
    ./stui.nix
    ./xdg.nix
    ./yazi
  ];

  home.packages = with pkgs; [
    mods
  ];
}
