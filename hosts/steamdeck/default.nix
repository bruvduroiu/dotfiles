{ lib, pkgs, config, inputs, ... }:

let
  mainUser = "deck";
in 
{
  imports = [
    ./hardware-configuration.nix
    ./transmission.nix
    ./kodi.nix
    ../../system/programs/niri
    ../../system/programs/fonts.nix
    ../../system/services/brightnessctl.nix
  ];

  # Steam Deck hardware support via Jovian-NixOS
  jovian = {
    decky-loader = {
      enable = true;
      user = "deck";
      stateDir = "/home/${mainUser}/.local/share/decky"; # Keep scoped to user

      # Decky's unit gets ONLY this list on its PATH (the module sets
      # `path = cfg.extraPackages`), on top of systemd's tiny default of
      # coreutils/findutils/grep/sed/systemd. Plugins shell out by bare name,
      # so anything missing here fails at runtime and nowhere else — the
      # plugin renders fine and simply reports nothing. TunnelDeck needs:
      #   networkmanager → nmcli, the whole plugin
      #   iproute2       → `ip -j route get` for its "priority interface" panel
      #   iputils        → ping, for its reachability check
      #   glibc.bin      → getent, to resolve steampowered.com
      # systemctl is already present via systemd.
      extraPackages = with pkgs; [
        networkmanager
        iproute2
        iputils
        glibc.bin

        # TunnelDeck offers an "Enable OpenVPN" switch that runs, as root, a
        # SteamOS-only script: wget + pacman + mksquashfs, writing a sysext to
        # /var/lib/extensions and calling /usr/share/libalpm/scripts. None of
        # that exists here, and none of it is needed — NetworkManager has
        # WireGuard built in, unlike OpenVPN.
        #
        # The plugin decides whether to offer that switch by running
        # `pacman -Qi networkmanager-openvpn` and catching CalledProcessError
        # only — so a missing pacman raises FileNotFoundError instead and the
        # switch renders in an undefined state. Answering the query honestly
        # ("installed") makes it render checked and disabled, i.e. unpressable.
        (writeShellScriptBin "pacman" ''
          # Narrow on purpose: any other pacman invocation should still fail,
          # so a future plugin cannot mistake this for a working package
          # manager.
          if [ "$1" = "-Qi" ] && [ "$2" = "networkmanager-openvpn" ]; then
            echo "Name            : networkmanager-openvpn"
            exit 0
          fi
          echo "pacman: not available on NixOS (stub)" >&2
          exit 1
        '')
      ];
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
      
      # Jovian owns the session switch in both directions.
      desktopSession = "niri";
    };

    steamos.useSteamOSConfig = true;

  };

  # Keep Nyx's vendored Jovian kernel, including its Valve patches.
  # enableKernelPatches selects linuxPackages_jovian, including Deck drivers.
  jovian.devices.steamdeck.enableKernelPatches = true;
  services.upower.enable = true;
  programs.dconf.enable = true;

  # System configuration
  # Steam Input's X11 keyboard/mouse output must reach native Wayland clients.
  programs.steam.extest.enable = true;

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
  #
  # wg0 runs on the NetworkManager backend rather than wg-quick. That is
  # purely so the tunnel exists as an NM *profile*: TunnelDeck (the Gaming
  # Mode VPN plugin) lists `nmcli connection show` filtered to types
  # vpn/wireguard, and a wg-quick interface is a kernel device with no
  # connection behind it — invisible. Same key, same peer, same routes; see
  # network.wireguard.backend for what changes and what does not.
  network.wireguard = {
    overlayIP = inputs.secrets.vars.hosts.steamdeck.wireguard.overlayIP;
    mullvad.enable = false;
    backend = "networkmanager";
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
    (makeDesktopItem {
      name = "return-to-gaming-mode";
      desktopName = "Return to Gaming Mode";
      exec = "${pkgs.steamos-manager}/bin/steamosctl switch-to-game-mode";
      icon = "steam";
      categories = [ "Game" ];
    })
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
