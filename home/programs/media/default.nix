{ pkgs, ... }:
# media - control and enjoy audio/video
{
  home.packages = with pkgs; [
    # audio control
    pulsemixer
    pwvucontrol
    helvum

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
