{ config, pkgs, lib, inputs, ... }:

{
  home.packages = with pkgs; [
    awscli
  ];

  # Profile names + endpoints live in the private flake's vars
  home.file."${config.home.homeDirectory}/.aws/config".text =
    lib.concatStrings (lib.mapAttrsToList (name: endpointUrl: ''
      [profile ${name}]
      endpoint_url = ${endpointUrl}

    '') inputs.secrets.vars.aws.profiles);
}
