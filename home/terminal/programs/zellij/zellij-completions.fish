# Session and layout names for zellij's fish completion. The package ships a
# clap-generated completions/zellij.fish with every flag and subcommand but no
# runtime values. fish autoloads one <cmd>.fish per command, so a second
# zellij.fish would shadow it; these rules are registered from conf.d instead
# and stack on top.

function __zellij_sessions
    for line in (zellij list-sessions --no-formatting 2>/dev/null)
        set -l name (string split -m1 ' ' -- $line)[1]
        if string match -q '*EXITED*' -- $line
            printf '%s\tdead session\n' $name
        else
            printf '%s\tlive session\n' $name
        end
    end
end

function __zellij_layouts
    set -l config $HOME/.config
    set -q XDG_CONFIG_HOME; and set config $XDG_CONFIG_HOME
    for f in $config/zellij/layouts/*.kdl
        printf '%s\tlayout\n' (basename $f .kdl)
    end
end

set -l session_subcommands attach a watch w kill-session k delete-session d
complete -c zellij -n "__fish_seen_subcommand_from $session_subcommands" -f -a '(__zellij_sessions)'
complete -c zellij -n "not __fish_seen_subcommand_from $session_subcommands" -s s -l session -x -a '(__zellij_sessions)'
complete -c zellij -s l -l layout -r -a '(__zellij_layouts)'
complete -c zellij -s n -l new-session-with-layout -r -a '(__zellij_layouts)'
