#
# These are very common and useful
#
function ll --description "List contents of directory using long format"
    exa -l --color-scale --color=auto --icons --group-directories-first $argv
end
