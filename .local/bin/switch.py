#!/usr/bin/python

import subprocess
import sys

layouts = [
    '`qwertyuiop[]asdfghjkl;\'zxcvbnm,./~@#$^&QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?№',
    'ёйцукенгшщзхъфывапролджэячсмитьбю.Ё"№;:?ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ#,',
]

keyboard_name = subprocess.run('hyprctl devices -j | gojq -jc ".keyboards | map(select(.main == true)) | .[0] | .name"', capture_output=True, text=True, shell=True).stdout

def get_current_layout_index() -> str:
    return 0 if subprocess.run(f'hyprctl devices -j | gojq -r \'.keyboards | map(select(.name == "{keyboard_name}")) | .[0] | .active_keymap\' | rg -iq "en"', shell=True).returncode == 0 else 1

def convert(layout_from:str, layout_to:str) -> str:
    for symbol in sys.stdin.read():
        if (index := layout_from.find(symbol)) > -1:
            print(layout_to[index], end='')
        else:
            print(symbol, end='')

def switch_layout_next() -> None:
    subprocess.run(['hyprctl', 'switchxkblayout', keyboard_name, 'next'], stdout=subprocess.DEVNULL)

def main():
    layout_current_index = get_current_layout_index()
    layout_target_index = 1 - layout_current_index

    convert(layouts[layout_current_index], layouts[layout_target_index])
    switch_layout_next()
    pass

if __name__ == '__main__':
    main()
