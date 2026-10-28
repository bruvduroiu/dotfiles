# Dev shell + recipes (instead of make/just). Recipes are real executables on
# PATH: direnv exports env vars only, so shellHook functions never reach the
# user's shell. Run `recipes` to list them.
{ pkgs, package }:

let
  inherit (pkgs) lib;

  recipe =
    name: description: runtimeInputs: text:
    pkgs.writeShellApplication {
      inherit name runtimeInputs text;
      meta.description = description;
    };

  recipes = [
    (recipe "dev" "run the app from source" [ pkgs.go ] ''go run . "$@"'')
    (recipe "tests" "go test ./..." [ pkgs.go ] ''go test ./... "$@"'')
    (recipe "lint" "go vet + formatting check" [ pkgs.go ] ''
      go vet ./...
      nix fmt -- --fail-on-change
    '')
    (recipe "push-image" "build .#image and push it to $REGISTRY" [ pkgs.skopeo ] ''
      : "''${REGISTRY:?set REGISTRY (host/namespace), e.g. in secrets.env.yaml}"
      archive=$(nix build .#image --no-link --print-out-paths)
      name=$(nix eval --raw .#image.imageName)
      tag=$(nix eval --raw .#image.imageTag)
      if [[ -n "''${REGISTRY_USER:-}" ]]; then
        printenv REGISTRY_PASSWORD | skopeo login --password-stdin -u "$REGISTRY_USER" "''${REGISTRY%%/*}"
      fi
      skopeo copy "docker-archive:$archive" "docker://$REGISTRY/$name:$tag"
    '')
    (recipe "secrets" "edit secrets.env.yaml (YubiKey touch)" [
      pkgs.sops
      pkgs.age-plugin-yubikey
    ] "sops edit secrets.env.yaml")
  ];

  pad = s: s + lib.concatStrings (lib.replicate (lib.max 1 (12 - lib.stringLength s)) " ");
  listing = recipe "recipes" "list recipes" [ ] ''
    cat <<'EOF'
    ${lib.concatMapStrings (r: "${pad r.name}${r.meta.description}\n") recipes}EOF
  '';
in
pkgs.mkShell {
  inputsFrom = [ package ];
  packages = recipes ++ [
    listing
    pkgs.gopls
    pkgs.sops
    pkgs.age-plugin-yubikey
  ];

  # Non-secret, committed dev config. Secrets go in secrets.env.yaml (.envrc).
  env = { };
}
