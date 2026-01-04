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

    # images
    loupe

    # videos
    celluloid
    grayjay

    # torrents
    transmission_4-gtk
  ];
}
