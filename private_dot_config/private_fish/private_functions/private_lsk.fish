function lsk --wraps='lsblk -o NAME,SIZE,MOUNTPOINTS' --description 'alias lsk=lsblk -o NAME,SIZE,MOUNTPOINTS'
  lsblk -o NAME,SIZE,MOUNTPOINTS $argv; 
end
