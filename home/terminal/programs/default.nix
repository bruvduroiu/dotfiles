{ pkgs, ... }:

{
  imports = [
    ./aws.nix
    ./bat.nix
    ./btop.nix
    ./claude
    ./cli.nix
    ./delta.nix
    ./direnv.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./gdu.nix
    ./git.nix
    ./jj.nix
    ./k9s.nix
    ./openspec.nix
    ./stui.nix
    ./tabiew.nix
    ./xdg.nix
    ./yazi
  ];

  home.packages = with pkgs; [
    mods
  ];
}
