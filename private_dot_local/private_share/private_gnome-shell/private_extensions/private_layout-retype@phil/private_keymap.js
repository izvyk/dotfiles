// Key tables and the conversion. No gnome-shell imports, so plain gjs can
// load it (with mutter's typelibs on GI_TYPELIB_PATH) for testing.
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';

Gio._promisify(Gio.Subprocess.prototype, 'communicate_utf8_async');

// One layout's keys, both ways: chars maps a character to the key that types
// it ({code: evdev keycode, shift}), keys maps "code/shift" back to the
// character. Levels 3–4 (AltGr) are left out: in a wrong-layout word they
// are almost never what was meant.
export async function keyTable(xkbId) {
    const [layout, variant] = xkbId.split('+');
    const argv = ['xkbcli', 'compile-keymap', '--layout', layout];
    if (variant)
        argv.push('--variant', variant);
    const proc = Gio.Subprocess.new(argv,
        Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
    const [stdout, stderr] = await proc.communicate_utf8_async(null, null);
    if (!proc.get_successful())
        throw new Error(`xkbcli compile-keymap ${xkbId}: ${stderr.trim()}`);
    return parseKeymap(stdout);
}

export function parseKeymap(text) {
    const codes = new Map();
    for (const [, name, code] of text.matchAll(/^\s*<([^>]+)>\s*=\s*(\d+)\s*;/gm))
        codes.set(name, Number(code));

    const keys = [];
    const symbols = text.slice(text.indexOf('xkb_symbols'));
    for (const [, name, body] of symbols.matchAll(/key\s+<([^>]+)>\s*\{([^}]*)\}/g)) {
        const list = (body.match(/symbols\[1\]\s*=\s*\[([^\]]*)\]/) ??
            body.match(/^\s*\[([^\]]*)\]/))?.[1];
        if (codes.has(name) && list)
            keys.push([codes.get(name), list.split(',').map(s => s.trim())]);
    }

    // Lowest keycode wins, so the main block beats the keypad.
    keys.sort((a, b) => a[0] - b[0]);
    const table = {chars: new Map(), keys: new Map()};
    for (const [code, names] of keys) {
        names.slice(0, 2).forEach((name, level) => {
            const char = keysymChar(name);
            const key = {code: code - 8, shift: level === 1};
            if (char && !table.chars.has(char))
                table.chars.set(char, key);
            if (char)
                table.keys.set(`${key.code}/${key.shift}`, char);
        });
    }
    return table;
}

// Printable character for a keysym name, or null. Control characters are
// dropped on purpose: Return or Tab are never typed.
function keysymChar(name) {
    let keyval;
    if (/^U[0-9A-Fa-f]{4,6}$/.test(name))
        keyval = 0x1000000 + parseInt(name.slice(1), 16);
    else if (/^0x[0-9A-Fa-f]+$/.test(name))
        keyval = parseInt(name, 16);
    else
        keyval = Clutter[`KEY_${name}`];
    if (!keyval)
        return null;
    const cp = Clutter.keysym_to_unicode(keyval);
    return cp >= 0x20 && cp !== 0x7f ? String.fromCodePoint(cp) : null;
}

// Retype every word in the other layout. Each word's own layout is the one
// with the most characters found only there, so "ghbdtn тшч" becomes
// "привет nix". A word with no such character ("...", "?", "123") takes the
// previous word's layout, or the current one. A character the word's layout
// lacks is kept as it is. Returns the new text and the layout index the last
// word went to (null when there were no words).
export function convert(text, tables, current) {
    const only = (word, i) => [...word].filter(c => tables[i].chars.has(c) &&
        tables.every((t, j) => j === i || !t.chars.has(c))).length;
    let source = current;
    let target = null;
    const out = text.split(/(\s+)/).map(word => {
        if (!word || /^\s+$/.test(word))
            return word;
        let best = 0;
        tables.forEach((_, i) => {
            const n = only(word, i);
            if (n > best) {
                best = n;
                source = i;
            }
        });
        target = (source + 1) % tables.length;
        return [...word].map(c => {
            const key = tables[source].chars.get(c);
            return (key && tables[target].keys.get(`${key.code}/${key.shift}`)) ?? c;
        }).join('');
    });
    return {text: out.join(''), target};
}
