{ pkgs, ... }:
# media - control and enjoy audio/video
{
  home.packages = with pkgs; [
    # audio control
    pulsemixer
    pwvucontrol
    crosspipe # helvum removed in nixpkgs 26.05 (unmaintained); crosspipe is the successor

    # audio
    amberol
    librepods

    # images
    loupe

    # videos
    celluloid
    grayjay
  ];
}
