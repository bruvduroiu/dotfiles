{ pkgs, ... }:

{
  imports = [
    ./aws.nix
    ./bat.nix
    ./btop.nix
    ./claude
    ./cli.nix
    ./crush.nix
    ./delta.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./gdu.nix
    ./git.nix
    ./jj.nix
    ./k9s.nix
    ./opencode
    ./openspec.nix
    ./stui.nix
    ./xdg.nix
    ./yazi
  ];

  home.packages = with pkgs; [
    mods
  ];
}
