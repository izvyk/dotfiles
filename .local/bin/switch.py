#!/usr/bin/python

import os
import sys

keyboard_name = "at-translated-set-2-keyboard"

layouts = [
    '`qwertyuiop[]asdfghjkl;\'zxcvbnm,./~@#$^&QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?',
    'ёйцукенгшщзхъфывапролджэячсмитьбю.Ё"№;:?ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,',
]

def get_current_layout_index() -> str:
    return 0 if os.system('hyprctl devices -j | gojq -r \'.keyboards | map(select(.name == "at-translated-set-2-keyboard")) | .[0] | .active_keymap\' | rg -iq "en"') == 0 else 1

def convert(layout_from:str, layout_to:str) -> str:
    for symbol in sys.stdin.read():
        if (index := layout_from.find(symbol)) > -1:
            print(layout_to[index], end='')
        else:
            print(symbol, end='')

def switch_layout_next() -> None:
    os.system(f"hyprctl switchxkblayout {keyboard_name} next > /dev/null")

def main():
    layout_current_index = get_current_layout_index()
    layout_target_index = 1 - layout_current_index

    convert(layouts[layout_current_index], layouts[layout_target_index])
    switch_layout_next()
    pass

if __name__ == '__main__':
    main()
