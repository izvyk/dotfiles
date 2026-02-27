function adm --wraps='doas fish --init-command=cd' --description 'Open fish shell as root in roots home directory'
  doas fish --init-command=cd $argv
        
end
