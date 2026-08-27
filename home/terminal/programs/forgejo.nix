{ config, pkgs, inputs, ... }: let
  # The instance is already in the clear in flake.nix — the private `secrets`
  # input is fetched over ssh from it — so the hostname stays out of the vars.
  host = "git.oolongtechnologies.io";

  # Inside a checkout `fj` infers the instance from the git remote. Everywhere
  # else (`fj repo search`, `fj org view`, `fj whoami`) it falls back to this,
  # and it warns and gives up on anything that isn't a URL with a scheme.
  fallbackHost = "https://${host}";

  # forgejo-cli resolves this through `directories::ProjectDirs` and exposes no
  # env var to move it, so the token has to land at exactly this path.
  keysFile = "${config.xdg.dataHome}/forgejo-cli/keys.json";
in {
  # Ships its own fish/bash/zsh completions under share/, picked up from the
  # profile — nothing to generate here.
  home.packages = [ pkgs.forgejo-cli ];

  home.sessionVariables.FJ_FALLBACK_HOST = fallbackHost;

  sops.secrets.forgejo_token = {
    sopsFile = "${inputs.secrets}/secrets/common/api-keys.yaml";
  };

  # There is no FJ_TOKEN: `fj` only ever reads the token out of keys.json.
  # Rendering the whole file as a sops template keeps the token off the
  # world-readable nix store — sops-install-secrets creates the parent dir and
  # points keysFile at the rendered copy. That copy is read-only, so `fj auth`
  # subcommands can no longer edit it; change this attrset instead.
  sops.templates."forgejo-keys.json" = {
    path = keysFile;
    mode = "0400";
    content = builtins.toJSON {
      hosts.${host} = {
        type = "Application";
        token = config.sops.placeholder.forgejo_token;
      };
      aliases = { };
      # Clone over ssh, matching how the `secrets` flake input is fetched.
      default_ssh = [ host ];
    };
  };
}
