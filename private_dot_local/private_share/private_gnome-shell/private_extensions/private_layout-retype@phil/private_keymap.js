// Key tables and the retype plan. No gnome-shell imports, so plain gjs can
// load it (with mutter's typelibs on GI_TYPELIB_PATH) for testing.
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';

Gio._promisify(Gio.Subprocess.prototype, 'communicate_utf8_async');

// Map from a character to the key that types it in one layout: an evdev
// keycode, plus whether Shift is held (level 2). Levels 3–4 (AltGr) are left
// out: in a wrong-layout word they are almost never what was meant.
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
    const table = new Map();
    for (const [code, names] of keys) {
        names.slice(0, 2).forEach((name, level) => {
            const char = keysymChar(name);
            if (char && !table.has(char))
                table.set(char, {code: code - 8, shift: level === 1});
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

// The layout the text was typed in is the one with the most characters found
// only there; on a tie, the current one. The target is the next layout.
// Characters the source lacks but the target has are kept as they are.
export function plan(text, tables, current) {
    const only = i => [...text].filter(c =>
        tables[i].has(c) && tables.every((t, j) => j === i || !t.has(c))).length;
    let from = current;
    tables.forEach((_, i) => {
        if (only(i) > only(from))
            from = i;
    });
    const to = (from + 1) % tables.length;

    const keys = [];
    for (const c of text) {
        const key = tables[from].get(c) ?? tables[to].get(c);
        if (!key)
            return {from, to, keys: null, missing: c};
        keys.push(key);
    }
    return {from, to, keys};
}
