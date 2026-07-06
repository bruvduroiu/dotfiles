{ pkgs, ... }: {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # battery reporting over GATT/HFP (upower / bluetui can read it)
      settings.General.Experimental = true;
      input = {
        General = {
          UserspaceHID = true;
        };
      };
    };
    
    # Ensure bluetooth is unblocked on boot
    systemd.services.bluetooth-unblock = { 
      description = "Unblock Bluetooth at boot";
      wantedBy = [ "bluetooth.service" ];
      before = [ "bluetooth.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };
  }
