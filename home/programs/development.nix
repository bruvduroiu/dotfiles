{ config, pkgs, ... }:

{
  imports = [
    ./aider.nix
  ];

  home.packages = with pkgs; [
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]))
    sops
    jq
    yq
    flyctl
    kubectl
    lazysql
    lazydocker
    lazyjournal
    opensnitch-ui
    posting
  ];
}
