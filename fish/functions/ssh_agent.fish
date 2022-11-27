function ssh_agent
if test -z (pgrep ssh-agent | string collect)
eval (ssh-agent -c)
set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
set -Ux SSH_AGENT_PID $SSH_AGENT_PID
end
end
