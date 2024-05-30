function __fish_complete_path --description "Complete using path"
    set -l target
    set -l description
    switch (count $argv)
        case 0
            # Dotfiles completion, otherwise pass
            set -l command "$(commandline -cpo)[2]"
            if test "$command" = "--git-dir=\$HOME/.dotfiles/"
                set target "$(commandline -ct)"
                set -e description 
            end
        case 1
            set target "$argv[1]"
        case 2 "*"
            set target "$argv[1]"
            set description "$argv[2]"

    end
    set -l targets (complete -C"'' $target")
    if set -q targets[1]
        printf "%s\n" $targets\t"$description"
    end
end
