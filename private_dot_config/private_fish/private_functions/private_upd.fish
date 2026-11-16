function upd --description 'Upgrade apt packages, then Nix: root channel (ns) and user profile (,)'
    function __upd_header
        set_color --bold blue
        echo "### $argv ###"
        set_color normal
    end

    __upd_header APT
    sudo apt update && sudo apt upgrade $argv
    or return

    __upd_header NIX CHANNEL
    # Absolute path: sudo's secure_path doesn't include Nix.
    sudo -H /nix/var/nix/profiles/default/bin/nix-channel --update
    or return

    __upd_header NIX PROFILE
    # Also refreshes comma's nix-index database (comma-with-db).
    nix --extra-experimental-features 'nix-command flakes' profile upgrade --all
end
