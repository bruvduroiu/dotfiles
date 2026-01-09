{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.opensnitch = {
    enable = true;

    # Configure OpenSnitch to exclude localhost and essential protocols
    # This prevents the NFQUEUE from blocking critical system traffic
    settings = {
      # Don't intercept localhost traffic to prevent queue backup breaking local services
      InterceptUnknown = false;

      # Use ebpf for process monitoring (more efficient than proc)
      ProcMonitorMethod = "ebpf";

      # System firewall configuration
      Firewall = "nftables";
    };

    rules = {
      "block-obsidian" = {
        name = "block-obsidian";
        enabled = true;
        action = "deny";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "process.path";
          data = "${lib.getBin pkgs.obsidian}/bin/obsidian";
        };
      };

      "allow-systemd-resolved" = {
        name = "allow-systemd-resolved";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "process.path";
          data = "${pkgs.systemd}/lib/systemd/systemd-resolved";
        };
      };

      # Allow all localhost connections without inspection
      "allow-localhost" = {
        name = "allow-localhost";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "dest.ip";
          data = "127.0.0.0/8";
        };
      };
    };
  };

  # Ensure localhost rule is enabled in system firewall config
  # This file is read by OpenSnitch to configure nftables rules
  environment.etc."opensnitchd/system-fw.json".text = lib.mkForce (builtins.toJSON {
    Enabled = true;
    Version = 1;
    SystemRules = [
      {
        Chains = [
          {
            Name = "output";
            Table = "mangle";
            Family = "inet";
            Priority = "";
            Type = "mangle";
            Hook = "output";
            Policy = "accept";
            Rules = [
              # CRITICAL: Allow localhost BEFORE queueing other traffic
              {
                Enabled = true;
                Position = "0";
                Description = "Allow localhost connections (prevent queue backup)";
                Expressions = [
                  {
                    Statement = {
                      Op = "==";
                      Name = "ip";
                      Values = [
                        {
                          Key = "daddr";
                          Value = "127.0.0.0-127.255.255.255";
                        }
                      ];
                    };
                  }
                ];
                Target = "accept";
                TargetParameters = "";
              }
              # ICMP rules follow
              {
                Enabled = true;
                Position = "1";
                Description = "Allow ICMP";
                Expressions = [
                  {
                    Statement = {
                      Op = "";
                      Name = "icmp";
                      Values = [
                        {
                          Key = "type";
                          Value = "echo-request,echo-reply,destination-unreachable";
                        }
                      ];
                    };
                  }
                ];
                Target = "accept";
                TargetParameters = "";
              }
              {
                Enabled = true;
                Position = "2";
                Description = "Allow ICMPv6";
                Expressions = [
                  {
                    Statement = {
                      Op = "";
                      Name = "icmpv6";
                      Values = [
                        {
                          Key = "type";
                          Value = "echo-request,echo-reply,destination-unreachable";
                        }
                      ];
                    };
                  }
                ];
                Target = "accept";
                TargetParameters = "";
              }
              # Queue all other new non-TCP connections for inspection
              {
                Enabled = true;
                Position = "3";
                Description = "Queue non-TCP connections for inspection";
                Expressions = [
                  {
                    Statement = {
                      Op = "!=";
                      Name = "meta";
                      Values = [
                        {
                          Key = "l4proto";
                          Value = "tcp";
                        }
                      ];
                    };
                  }
                  {
                    Statement = {
                      Op = "";
                      Name = "ct";
                      Values = [
                        {
                          Key = "state";
                          Value = "new,related";
                        }
                      ];
                    };
                  }
                ];
                Target = "queue";
                TargetParameters = "num 0 bypass";
              }
              # Queue new TCP connections
              {
                Enabled = true;
                Position = "4";
                Description = "Queue new TCP connections";
                Expressions = [
                  {
                    Statement = {
                      Op = "==";
                      Name = "tcp";
                      Values = [
                        {
                          Key = "flags";
                          Value = "syn";
                        }
                      ];
                    };
                  }
                ];
                Target = "queue";
                TargetParameters = "num 0 bypass";
              }
            ];
          }
        ];
      }
    ];
  });
}
