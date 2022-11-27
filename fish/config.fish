if status is-interactive
    # Commands to run in interactive sessions can go here
end

source ~/.iterm2_shell_integration.fish

# Keyboard repeat
defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)


# Aliases
alias l="ls -lah"

alias vim="nvim"
alias vimdiff="nvim -d"

alias gs="git status --short"
alias gll="git log --graph --oneline --all"

alias k="kubectl"

alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"

alias li="linode-cli"


# Environment variables
set -x PATH /Users/bogdan/development/tools/tools/bin $PATH

# Pyenv
status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source

# DigitalOcean
source (doctl completion fish|psub)


# Access Keys
set -x KUBE_CONFIG_PATH ~/.kube/config

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/bogdanbuduroiu/google-cloud-sdk/path.fish.inc' ]; . '/Users/bogdanbuduroiu/google-cloud-sdk/path.fish.inc'; end
