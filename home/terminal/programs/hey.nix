{ pkgs, ... }:

{
  # Completions ship in the package's share/, picked up from the profile.
  home.packages = [ pkgs.hey-cli ];

  # hey is offered to agents through OpenWork's MCP config only
  # (home/programs/openwork.nix). Bare `hey` runs a setup wizard that would
  # otherwise install a Claude Code plugin and a shared ~/.agents skill.
  home.sessionVariables.HEY_SETUP_AGENT = "none";

  # The OAuth login rotates its refresh token on every refresh, so it can't
  # live in sops: hey keeps it in the Secret Service keyring that KeePassXC
  # serves (home/programs/keepassxc.nix). Sign in once per host with
  # `hey auth login`; a refresh token shared between installs gets revoked.
  #
  # Without this marker, hey falls back to plaintext credentials.json
  # whenever its keyring probe fails, e.g. when KeePassXC isn't running yet.
  # With it, hey stays on the keyring and errors until the database is
  # unlocked. hey's own attempt to rewrite the marker hits this read-only
  # store symlink and is ignored.
  xdg.configFile."hey-cli/credential-storage".text = "keyring\n";
}
