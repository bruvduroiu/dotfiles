{ config, pkgs, ... }:

{
  imports = [
    ./aider.nix
  ];

  home.packages = with pkgs; [
    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
    sops
    jq
    yq
    kubectl
    lazysql
    lazydocker
    docling
  ];
}
