function fish_ssh_agent --description "Start ssh-agent if it's not running"
    if not pidof ssh-agent > /dev/null || [ "$(pidof ssh-agentt)" != "$SSH_AGENT_PID" ]
        eval $(ssh-agent -c) > /dev/null
    end
end
