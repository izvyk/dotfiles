function nsu --description 'nix-shell (unstable) wrapper executing fish'
    set -l next_level 1
    if set -q NIX_SHELL_DEPTH
        set next_level (math $NIX_SHELL_DEPTH + 1)
    end

    NIX_SHELL_DEPTH=$next_level command nix-shell -I nixpkgs=channel:nixpkgs-unstable --run "exec fish" -p $argv
end
