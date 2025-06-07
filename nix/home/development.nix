{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development tools
    neovim
    git
    kubectl
    terraform
    docker
    docker-compose
    
    # Cloud tools
    google-cloud-sdk
    doctl
    linode-cli
    
    # Python
    python3
    pyenv
    
    # Node.js tools
    nodejs
    bun
    
    # Other tools from your completions
    caddy
    cilium
    fzf
    hugo
    yq
    goreleaser
    temporal
    poetry
    uv
    mods
    
    # Fonts
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];

  # Neovim configuration
  home.file.".config/nvim" = {
    source = ../../config/nvim;
    recursive = true;
  };

  # Git configuration
  programs.git = {
    enable = true;
    # Add your git config here
  };

  # Docker
  # Note: Docker daemon needs to be enabled at system level
}
