function fish_ssh_agent --description "Start ssh-agent if it's not running"
    if not pidof ssh-agent >/dev/null
        eval "$(ssh-agent -c | head -2)"
        echo STARTING SSH AGENT
    end
end
