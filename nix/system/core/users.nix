{ pkgs, ... }: {
    users.users.bogdan = {
      isNormalUser = true;
      extraGroups = [
        "input"
        "wheel"
        "networkManager"
      ];
    };
  }
