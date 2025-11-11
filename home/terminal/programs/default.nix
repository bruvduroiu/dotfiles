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
    ./happy.nix
    ./k9s.nix
    ./openspec.nix
    ./stui.nix
    ./xdg.nix
    ./yazi
  ];

  home.packages = with pkgs; [
    mods
  ];
}
