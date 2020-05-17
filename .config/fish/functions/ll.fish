#
# These are very common and useful
#
function ll --description "List contents of directory using long format"
    lsd -lh --group-dirs=first $argv
end
