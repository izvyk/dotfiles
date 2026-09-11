function conf --wraps='doas fish -l -C cd /etc/nixos' --description 'Open fish login shell as root and cd into /etc/nixos'
    /run/wrappers/bin/doas /run/current-system/sw/bin/fish -l -C 'cd /etc/nixos'
end
