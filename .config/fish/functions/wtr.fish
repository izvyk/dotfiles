# Defined in - @ line 1
function wtr --wraps='curl http://wttr.in' --description 'alias wtr=curl http://wttr.in'
  curl http://wttr.in $argv;
end
