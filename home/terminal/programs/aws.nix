{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli
  ];

  home.file."${config.home.homeDirectory}/.aws/config".text = ''
    [profile saturn-prod]
    endpoint_url = https://hel1.your-objectstorage.com

    [profile saturn-staging]
    endpoint_url = https://hel1.your-objectstorage.com

    [profile archipelago]
    endpoint_url = https://s3.local.buduroiu.com
  '';
}
