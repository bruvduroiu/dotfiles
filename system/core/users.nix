{ pkgs, ... }: {
    users.users.bogdan = {
      shell = pkgs.fish;
      # This is needed because this part runs before the shell activation 
      ignoreShellProgramCheck = true;
      isNormalUser = true;
      extraGroups = [
        "input"
        "wheel"
        "networkManager"
      ];
    };
  }
