{ config, pkgs, ... }:

{
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
    sqlit-tui
    lazydocker
    lazyjournal
    opensnitch-ui
    posting
  ];
}
