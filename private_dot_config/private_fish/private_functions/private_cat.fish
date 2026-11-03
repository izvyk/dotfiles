function cat --wraps=bat --description 'bat (plain when piped), else cat'
    if type -q bat
        bat $argv
    else if type -q batcat # Debian/Ubuntu name
        batcat $argv
    else
        command cat $argv
    end
end
