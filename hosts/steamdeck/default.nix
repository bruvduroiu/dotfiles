{ lib, pkgs, config, inputs, ... }:

let
  mainUser = "deck";
in 
{
  imports = [
    ./hardware-configuration.nix
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

  # Tailscale configuration (operator is deck user)
  services.tailscale.extraUpFlags = lib.mkForce [ "--operator=deck" ];

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
    # SSH key for remote deployment from Framework13
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJSSumawcqD5McYyYcwPKuhKouMnR0Fy4B+lDhMAfuH bogdan@nixos"
    ];
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
