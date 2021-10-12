#
# These are very common and useful
#
function la --description "List contents of directory, including hidden files in directory using long format"
    exa -la --color-scale --color=auto --icons --group-directories-first $argv
end

