{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-symbols

      # Sans(serif) fonts
      libertinus
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      roboto
      (google-fonts.override {fonts = ["Inter"];})

      # monospace fonts
      jetbrains-mono

      # nerd fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];

    enableDefaultPackages = false;

    fontconfig.defaultFonts = {
      serif = ["Libertinus Serif"];
      sansSerif = ["Inter"];
      monospace = ["Jetbrains Mono Nerd Font"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
