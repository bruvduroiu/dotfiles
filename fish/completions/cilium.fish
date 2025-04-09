Generate the autocompletion script for cilium for the specified shell.
See each sub-command's help for details on how to use the generated script.

Usage:
  cilium completion [command]

Available Commands:
  bash        Generate the autocompletion script for bash
  fish        Generate the autocompletion script for fish
  powershell  Generate the autocompletion script for powershell
  zsh         Generate the autocompletion script for zsh

Flags:
  -h, --help   help for completion

Global Flags:
      --context string             Kubernetes configuration context
      --helm-release-name string   Helm release name (default "cilium")
  -n, --namespace string           Namespace Cilium is running in (default "kube-system")

Use "cilium completion [command] --help" for more information about a command.
