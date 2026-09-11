# Defined in - @ line 1
function cat --wraps='bat --theme=1337' --description 'alias cat=bat --theme=1337'
  bat --theme=1337 $argv;
end
