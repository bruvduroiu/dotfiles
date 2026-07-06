# Home Manager common settings
# The actual nixosModule is imported per-host in hosts/default.nix
# to allow different home-manager versions (stable vs unstable)
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
