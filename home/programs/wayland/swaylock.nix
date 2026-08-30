{ pkgs, ... }:

# Locker for the niri session (hyprlock.{nix} stays alongside for the
# Hyprland hosts). swaylock: tiny, battle-tested, ext-session-lock.
# Colours/background come from the stylix swaylock target.
#
# Fingerprint goes through PAM (security.pam.services.swaylock in
# system/programs/niri + fprintd): touch the sensor, or type the password
# and press Enter. Unlike hyprlock the two run serially, not in parallel —
# if that grates, swapping the import back to hyprlock.nix is the revert.
{
  programs.swaylock = {
    enable = true;
    settings = {
      ignore-empty-password = true;
      show-failed-attempts = true;
      indicator-caps-lock = true;
      indicator-radius = 100;
      # match hyprlock's immediate_render/no_fade_in: paint before the
      # panel blanks so waking shows the lock instantly
      daemonize = false;
    };
  };
}
