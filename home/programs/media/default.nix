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

    # torrents
    transmission_4-gtk
  ];
}
