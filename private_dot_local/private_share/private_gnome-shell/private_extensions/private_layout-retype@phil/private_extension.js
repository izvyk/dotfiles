// Retype text in the other keyboard layout, Punto Switcher style:
//   AltGr+Space        the word before the cursor, or the selection
//   AltGr+Shift+Space  the whole line before the cursor
// (keyd in nixos-config turns these into F22 and F23, which are grabbed here.)
// With the cursor at a line start, both take the line after it.
// Each word goes from its own layout to the other ("ghbdtn тшч" → "привет
// nix"); pressing again flips it back. Afterwards the layout is switched to
// the last word's new one.
//
// Text fields: reads the text around the cursor and replaces it through the
// input-method protocol (text-input-v3), as GNOME's on-screen keyboard does.
// No selecting and no key presses, so whatever happened in the field before
// (Ctrl+Backspace, paste, clicks) doesn't matter. Password fields are skipped.
//
// Elsewhere (terminals, Zed, apps without text-input): falls back
// to the primary selection and types the result through gnome-shell's own
// virtual keyboard. Select the text first.
//
// Key tables come from `xkbcli compile-keymap` (libxkbcommon), which reads
// ~/.config/xkb as GNOME does.
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import St from 'gi://St';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {getInputSourceManager} from 'resource:///org/gnome/shell/ui/status/keyboard.js';

import {convert, keyTable} from './keymap.js';

const WORD_ACCELERATOR = 'F22';
const LINE_ACCELERATOR = 'F23';
const MAX_LENGTH = 1000;
const KEY_LEFTSHIFT = 42; // evdev code
const HELD = Clutter.ModifierType.SHIFT_MASK | Clutter.ModifierType.CONTROL_MASK |
    Clutter.ModifierType.MOD1_MASK | Clutter.ModifierType.MOD4_MASK |
    Clutter.ModifierType.SUPER_MASK | Clutter.ModifierType.HYPER_MASK |
    Clutter.ModifierType.META_MASK;
const {PASSWORD, PIN, TERMINAL} = Clutter.InputContentPurpose;
// Apps whose field text in mutter goes stale: they send it only on
// input-method events. Deleting by stale
// offsets would hit the wrong characters, so these get the selection
// fallback. Matched against the window's app id (desktop file name).
const STALE_TEXT_APPS = new Set(['dev.zed.Zed']);

export default class LayoutRetypeExtension extends Extension {
    enable() {
        this._tables = new Map();
        this._timeouts = new Set();
        this._busy = false;
        this._keyboard = Clutter.get_default_backend().get_default_seat()
            .create_virtual_device(Clutter.InputDeviceType.KEYBOARD_DEVICE);

        this._actions = new Map();
        for (const [accelerator, line] of [[WORD_ACCELERATOR, false], [LINE_ACCELERATOR, true]]) {
            const action = global.display.grab_accelerator(accelerator, Meta.KeyBindingFlags.NONE);
            if (action === Meta.KeyBindingAction.NONE) {
                console.error(`layout-retype: could not grab ${accelerator}`);
                continue;
            }
            Main.wm.allowKeybinding(Meta.external_binding_name_for_action(action),
                Shell.ActionMode.NORMAL);
            this._actions.set(action, line);
        }
        this._accelId = global.display.connect('accelerator-activated', (_d, action) => {
            if (this._actions.has(action))
                this._retype(this._actions.get(action));
        });
    }

    disable() {
        global.display.disconnect(this._accelId);
        for (const action of this._actions.keys()) {
            global.display.ungrab_accelerator(action);
            Main.wm.allowKeybinding(Meta.external_binding_name_for_action(action),
                Shell.ActionMode.NONE);
        }
        for (const id of this._timeouts)
            GLib.source_remove(id);
        this._actions = null;
        this._timeouts = null;
        this._tables = null;
        this._keyboard = null;
        this._accelId = null;
    }

    async _retype(line) {
        if (this._busy)
            return;
        this._busy = true;
        try {
            await this._run(line);
        } catch (e) {
            console.error(`layout-retype: ${e.message}`);
            Main.notify('Layout retype', e.message);
        } finally {
            this._busy = false;
        }
    }

    async _run(line) {
        const ism = getInputSourceManager();
        const sources = Object.values(ism.inputSources)
            .filter(s => s.type === 'xkb')
            .sort((a, b) => a.index - b.index);
        if (sources.length < 2)
            throw new Error('Needs at least two keyboard layouts');
        const tables = await Promise.all(sources.map(s => this._table(s.id)));
        const current = Math.max(0, sources.indexOf(ism.currentSource));

        const im = Main.inputMethod;
        if (im.contentPurpose === PASSWORD || im.contentPurpose === PIN)
            return;
        let target; // undefined: the field gave no text, use the selection
        const appId = Shell.WindowTracker.get_default().focus_app?.get_id()
            ?.replace(/\.desktop$/, '');
        if (im.currentFocus && im.contentPurpose !== TERMINAL && !im.hasPreedit() &&
            !STALE_TEXT_APPS.has(appId))
            target = await this._replaceInField(im, line, tables, current);
        if (target === undefined)
            target = await this._typeSelection(tables, current, sources, ism);
        if (target !== null && this._keyboard)
            await this._activate(sources[target]);
    }

    // Returns the target layout index, null if there was nothing to convert,
    // or undefined if the field doesn't share its text.
    async _replaceInField(im, line, tables, current) {
        // The text the app last sent; mutter can't ask for a fresh one
        // (request_surrounding only replays it). Firefox, GTK and Chromium
        // send it on every change.
        const [text, cursor, anchor] = im.getSurroundingText();
        if (text === null || text === undefined)
            return undefined;
        // Offsets count characters, not UTF-16 units.
        const chars = [...text];

        if (cursor !== anchor) {
            // A commit replaces the selection.
            const selected = chars.slice(Math.min(cursor, anchor), Math.max(cursor, anchor));
            const result = convert(selected.join(''), tables, current);
            if (result.target !== null)
                im.commit(result.text);
            return result.target;
        }

        // GTK3 apps (Firefox) and Chromium report no selection bound, only
        // the cursor at one of its ends. So if the primary selection sits right
        // before or after the cursor, take that. A selection just collapsed
        // with an arrow key still counts.
        const primary = line ? '' : [...(await this._primary()) ?? ''];
        if (primary.length > 0 && primary.length <= MAX_LENGTH) {
            const p = primary.join('');
            const before = cursor >= primary.length
                ? chars.slice(cursor - primary.length, cursor).join('') : null;
            const after = chars.slice(cursor, cursor + primary.length).join('');
            if (before === p || after === p) {
                const result = convert(p, tables, current);
                if (result.target === null)
                    return null;
                if (before === p)
                    im.delete_surrounding(-primary.length, primary.length);
                else
                    im.delete_surrounding(0, primary.length);
                im.commit(result.text);
                return result.target;
            }
        }

        // Cursor at a line start (Firefox puts it there on Ctrl+A, without
        // touching the primary selection): take the line after it.
        if (cursor === 0 || chars[cursor - 1] === '\n') {
            let end = cursor;
            while (end < chars.length && chars[end] !== '\n')
                end++;
            if (end - cursor > MAX_LENGTH)
                throw new Error(`Longer than ${MAX_LENGTH} characters`);
            const result = convert(chars.slice(cursor, end).join(''), tables, current);
            if (result.target === null)
                return null;
            im.delete_surrounding(0, end - cursor);
            im.commit(result.text);
            return result.target;
        }

        // Back over trailing spaces, then over the word (or to line start).
        let start = cursor;
        while (start > 0 && /[^\S\n]/.test(chars[start - 1]))
            start--;
        while (start > 0 && chars[start - 1] !== '\n' && (line || !/\s/.test(chars[start - 1])))
            start--;
        if (cursor - start > MAX_LENGTH)
            throw new Error(`Longer than ${MAX_LENGTH} characters`);
        const result = convert(chars.slice(start, cursor).join(''), tables, current);
        if (result.target === null)
            return null;
        im.delete_surrounding(start - cursor, cursor - start);
        im.commit(result.text);
        return result.target;
    }

    _primary() {
        return new Promise(resolve => St.Clipboard.get_default()
            .get_text(St.ClipboardType.PRIMARY, (_c, t) => resolve(t)));
    }

    async _typeSelection(tables, current, sources, ism) {
        const text = await this._primary();
        if (!text)
            return null;
        if (text.length > MAX_LENGTH)
            throw new Error(`Selection is longer than ${MAX_LENGTH} characters`);
        const result = convert(text, tables, current);
        if (result.target === null)
            return null;

        // Each character in a layout that has it, switching only when needed.
        let active = current;
        const plan = [];
        for (const c of result.text) {
            if (!tables[active].chars.has(c))
                active = tables.findIndex(t => t.chars.has(c));
            if (active < 0)
                throw new Error(`"${c}" is on none of the layouts`);
            plan.push([active, tables[active].chars.get(c)]);
        }

        // The shortcut's own keys must be up, or apps see Super+letters.
        if (!await this._modifiersReleased())
            throw new Error('Modifier keys are still held');
        const key = (code, pressed) => this._keyboard?.notify_key(GLib.get_monotonic_time(),
            code, pressed ? Clutter.KeyState.PRESSED : Clutter.KeyState.RELEASED);
        for (const [layout, {code, shift}] of plan) {
            if (ism.currentSource !== sources[layout])
                await this._activate(sources[layout]);
            if (shift)
                key(KEY_LEFTSHIFT, true);
            key(code, true);
            key(code, false);
            if (shift)
                key(KEY_LEFTSHIFT, false);
        }
        return result.target;
    }

    async _table(xkbId) {
        if (!this._tables.has(xkbId))
            this._tables.set(xkbId, await keyTable(xkbId));
        return this._tables.get(xkbId);
    }

    async _modifiersReleased() {
        for (let i = 0; i < 150; i++) {
            const [, , mods] = global.get_pointer();
            if ((mods & HELD) === 0)
                return true;
            await this._sleep(20);
        }
        return false;
    }

    // Keys typed before the switch lands would come out in the old layout.
    async _activate(source) {
        if (getInputSourceManager().currentSource === source)
            return;
        const backend = global.backend;
        let ids = [];
        const switched = new Promise(resolve => {
            ids = ['keymap-layout-group-changed', 'keymap-changed']
                .map(signal => backend.connect(signal, resolve));
        });
        source.activate(true);
        await Promise.race([switched, this._sleep(500)]);
        ids.forEach(id => backend.disconnect(id));
    }

    _sleep(ms) {
        return new Promise(resolve => {
            const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
                this._timeouts?.delete(id);
                resolve();
                return GLib.SOURCE_REMOVE;
            });
            this._timeouts.add(id);
        });
    }
}
