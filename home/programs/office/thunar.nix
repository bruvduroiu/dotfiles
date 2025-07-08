{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-vcs-plugin
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.tumbler
  ];
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
      <icon>utilities-x-terminal</icon>
      <name>Open Terminal Here</name>
      <submenu></submenu>
      <unique-id>1747642747798278-1</unique-id>
      <command>ghostty --working-directory %f</command>
      <description>Open terminal here</description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    <action>
      <icon>nvim</icon>
      <name>Open file with neovim</name>
      <submenu></submenu>
      <unique-id>1747716628944583-1</unique-id>
      <command>ghostty --working-directory %d nvim %F</command>
      <description>Open file with nvim </description>
      <range></range>
      <patterns>*</patterns>
      <startup-notify/>
      <directories/>
    </action>
    </actions>
  '';
}
