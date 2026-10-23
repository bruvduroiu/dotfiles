# fish completions for zj (zj.sh): targets are live/dead sessions, project
# directories under $ZJ_PROJECT_ROOTS, or any directory; -l takes a layout
# name from ~/.config/zellij/layouts.

function __zj_sessions
    for line in (zellij list-sessions --no-formatting 2>/dev/null)
        set -l name (string split -m1 ' ' -- $line)[1]
        if string match -q '*EXITED*' -- $line
            printf '%s\tdead session\n' $name
        else
            printf '%s\tlive session\n' $name
        end
    end
end

function __zj_projects
    set -l roots $HOME/development
    set -q ZJ_PROJECT_ROOTS; and set roots (string split : -- $ZJ_PROJECT_ROOTS)
    for root in $roots
        for dir in $root/*/
            printf '%s\tproject\n' (basename $dir)
        end
    end
end

function __zj_layouts
    set -l config $HOME/.config
    set -q XDG_CONFIG_HOME; and set config $XDG_CONFIG_HOME
    for f in $config/zellij/layouts/*.kdl
        basename $f .kdl
    end
end

# True until a target has been given (option arguments don't count).
function __zj_needs_target
    set -l argv (commandline -opc)[2..]
    argparse -i 'l=' h -- $argv 2>/dev/null
    test (count $argv) -eq 0
end

complete -c zj -f
complete -c zj -s l -x -a '(__zj_layouts)' -d 'layout for a new session'
complete -c zj -s h -d 'show usage'
complete -c zj -n __zj_needs_target -a '(__zj_sessions)'
complete -c zj -n __zj_needs_target -a '(__zj_projects)'
complete -c zj -n __zj_needs_target -a '(__fish_complete_directories)'
