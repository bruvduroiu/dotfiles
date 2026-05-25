{ config
, pkgs
, ... 
}:

let
  superpowersSrc = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "v5.0.7";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    # Waiting for home-manager to get these
    # web.enable = true;
    package = pkgs.opencode;

    settings = {
      enabled_providers = [ "deepseek" "openrouter" ];
      provider = {
        deepseek = {
          options = {
            apiKey = "{file:${config.sops.secrets.deepseek_api_key.path}}";
          };
        };
        openrouter = {
          options = {
            apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
          };
        };
      };
      plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
      autoshare = false;
      autoupdate = true;
      model = "deepseek/deepseek-v4-pro";
      # TODO: Migrate to programs.opencode.tools when home-manager supports it
      # tools = {
      #   dd-log = ./tools/dd-log.ts;
      # };
      permission = {
        "*" = "allow";
        "skill" = {
          "*" = "allow";
        };
        "bash" = {
          "*" = "allow";
          "touch *" = "ask";
          "mkdir *" = "ask";
          "rm *" = "ask";
          "cp *" = "ask";
          "mv *" = "ask";
          "dd *" = "ask";
          "sudo *" = "ask";
          "chmod *" = "ask";
          "chown *" = "ask";
          "curl *" = "ask";
          "wget *" = "ask";
          "npm install *" = "ask";
          "pip install *" = "ask";
          "git push" = "ask";
          "git reset --hard *" = "ask";
          "git clean *" = "ask";
          "reboot" = "ask";
          "shutdown" = "ask";
          "kill *" = "ask";
          "killall *" = "ask";
          "docker *" = "ask";
          "mkfs *" = "ask";
          "fdisk *" = "ask";
          "parted *" = "ask";
          "format *" = "ask";
          "git branch -d *" = "ask";
          "git branch -D *" = "ask";
          "git rebase *" = "ask";
          "npm run publish" = "ask";
          "ssh *" = "ask";
          "scp *" = "ask";
          "nix *" = "ask";
          "nixos-rebuild *" = "ask";
        };
        "doom_loop" = "ask";
        "external_directory" = {
          "/tmp/**" = "allow";
        };
      };
    };

    agents = {
      plan = ./agents/plan.md;
    };
  };

  # TODO: Remove when programs.opencode.tools is available in home-manager
  xdg.configFile = {
    "opencode/tools/dd-log.ts".source = ./tools/dd-log.ts;
  };
}
