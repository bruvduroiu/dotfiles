{ pkgs, ... }:

{
  imports = [
    ./aws.nix
    ./bat.nix
    ./btop.nix
    ./claude
    ./cli.nix
    ./codex
    ./delta.nix
    ./direnv.nix
    ./eza.nix
    ./fd.nix
    ./forgejo.nix
    ./fzf.nix
    ./gdu.nix
    ./git.nix
    ./jj.nix
    ./k9s.nix
    ./opencode
    ./skepsis.nix
    ./stui.nix
    ./tabiew.nix
    ./xdg.nix
    ./yazi
    ./zellij
  ];

  home.packages = with pkgs; [
    mods
    uber-receipts
    portfolio-tracker
    mullvad-jump
    tz
  ];
}
