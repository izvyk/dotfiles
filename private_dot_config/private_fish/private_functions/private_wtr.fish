function wtr --wraps='curl https://wttr.in' --description 'alias wtr=curl https://wttr.in'
  curl https://wttr.in $argv;
end
