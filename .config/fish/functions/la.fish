#
# These are very common and useful
#
function la --description "List contents of directory, including hidden files in directory using long format"
    lsd -lAh --group-dirs=first $argv
end

