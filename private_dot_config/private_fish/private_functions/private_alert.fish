function alert --description 'Desktop notification when a long command ends: sleep 10; alert'
    set -l code $status
    if test $code -eq 0
        notify-send --urgency=low -i terminal Done (prompt_pwd)
    else
        notify-send --urgency=low -i error "Failed ($code)" (prompt_pwd)
    end
end
