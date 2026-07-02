{ config
, lib
, pkgs
, ...
}:

let
  lspDeps = import ./lsp-deps.nix { inherit pkgs; };
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    web.enable = true;

    agents = {
      plan = ./agents/plan.md;
      code = ./agents/code.md;
      code-review = ./agents/code-review.md;
    };

    skills = { };

    settings = {
      enabled_providers = [ "deepseek" "openrouter" "zai-coding-plan" ];
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
        # Z.AI Coding Plan (subscription endpoint, GLM models). Provider id
        # from models.dev; hits https://api.z.ai/api/coding/paas/v4.
        zai-coding-plan = {
          options = {
            apiKey = "{file:${config.sops.secrets.zai_api_key.path}}";
          };
        };
      };
      plugin = [ "superpowers@git+https://github.com/obra/superpowers.git" ];
      autoshare = false;
      autoupdate = true;
      model = "deepseek/deepseek-v4-pro";
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
  };

  # Tools must be real files, not symlinks into /nix/store: opencode's
  # embedded Bun resolves `@opencode-ai/plugin` from the importer's
  # realpath, and the store has no node_modules ancestor. Copying keeps
  # resolution anchored at ~/.config/opencode, where opencode auto-installs
  # the plugin package.
  home.activation.opencodeToolsCopy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.configHome}/opencode/tools"
    run install -m 0644 ${./tools}/*.ts "${config.xdg.configHome}/opencode/tools/"
  '';

  # Symlink nix-built node_modules into the repo checkout so the editor LSP
  # resolves @opencode-ai/plugin in tools/*.ts without any npm install.
  # Guarded: only hosts that have the dotfiles checkout get the link.
  home.activation.opencodeLspDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    opencodeRepoDir="$HOME/development/dotfiles/home/terminal/programs/opencode"
    if [ -d "$opencodeRepoDir" ]; then
      run ln -sfnT ${lspDeps} "$opencodeRepoDir/node_modules"
    fi
  '';
}
