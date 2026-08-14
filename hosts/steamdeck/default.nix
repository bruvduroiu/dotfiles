{ lib, pkgs, config, inputs, ... }:

let
  mainUser = "deck";
in 
{
  imports = [
    ./hardware-configuration.nix
    ./transmission.nix
    ./kodi.nix
  ];

  # Steam Deck hardware support via Jovian-NixOS
  jovian = {
    decky-loader = {
      enable = true;
      user = "deck";
      stateDir = "/home/${mainUser}/.local/share/decky"; # Keep scoped to user
    };
    devices.steamdeck = {
      enable = true;
      enableGyroDsuService = true;
      autoUpdate = true;
    };

    hardware.has.amd.gpu = true;
    
    steam = {
      enable = true;
      autoStart = true;
      user = mainUser;
      
      # Switch to Plasma desktop when using "Switch to Desktop" in Gaming Mode
      desktopSession = "plasma";
    };

    steamos.useSteamOSConfig = true;

  };

  # Plasma Desktop for "Switch to Desktop" functionality
  services.desktopManager.plasma6.enable = true;

  # System configuration
  networking.hostName = "steamdeck";

  # WireGuard peer identity (see system/network/wireguard.nix).
  #
  # HOME OVERLAY ONLY — no Mullvad. The deck is a stationary console on the
  # home LAN whose whole job is to be reachable (SSH, Syncthing, Kodi,
  # Transmission); an egress tunnel buys it nothing and costs it a second
  # private key plus the policy-routing rules that own its default route.
  #
  # overlayIP is spelled out rather than splatting the whole
  # vars.hosts.steamdeck.wireguard attrset, because that attrset still carries
  # mullvadAddressV4/V6 placeholders. Those are bound to a Mullvad device key
  # the deck does not have, and a placeholder Mullvad address is the failure
  # mode that handshakes happily and then drops every packet.
  network.wireguard = {
    overlayIP = inputs.secrets.vars.hosts.steamdeck.wireguard.overlayIP;
    mullvad.enable = false;
  };

  # sops decryption identity for this host. The deck is headless and never
  # holds the YubiKey, so it keeps a software age key instead of the laptop's
  # YubiKey identity from system/core/sops.nix — mkForce because that default
  # points at /home/bogdan, a user that does not exist here.
  #
  # Lives at host level, not in transmission.nix where it used to sit: WireGuard
  # and Syncthing both depend on it, so it must not disappear if torrents ever do.
  sops.age.keyFile = lib.mkForce "/home/deck/.config/sops/age/keys.txt";

  # Boot optimizations for gaming
  boot.kernelParams = [ "amd_pstate=active" ];

  # Enable flakes and trust deck user for remote deployments
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Allow deck user to copy unsigned store paths from remote machines
    trusted-users = [ "root" "deck" ];
  };

  # Allow unfree packages (Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # User configuration
  users.users.deck = {
    isNormalUser = true;
    shell = pkgs.bash;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    # SSH key for remote deployment from Framework13 (private flake vars)
    openssh.authorizedKeys.keys = inputs.secrets.vars.hosts.steamdeck.sshAuthorizedKeys;
  };

  # Sudo without password for remote nixos-rebuild
  security.sudo.extraRules = [
    {
      users = [ "deck" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    steam-rom-manager  # For adding non-Steam games/ROMs
  ];

  # State version - matches when NixOS was first installed on Steam Deck
  # Use mkForce since system/core sets a default
  system.stateVersion = lib.mkForce "25.11";

  systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
  description = "Create Steam CEF debugging file";
  serviceConfig = {
    Type = "oneshot";
    User = config.jovian.steam.user;
    ExecStart = "/bin/sh -c 'mkdir -p ~/.steam/steam && [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true'";
  };
  wantedBy = [ "multi-user.target" ];
};
}
