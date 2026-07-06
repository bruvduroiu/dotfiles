{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    timewarrior
  ];
}
