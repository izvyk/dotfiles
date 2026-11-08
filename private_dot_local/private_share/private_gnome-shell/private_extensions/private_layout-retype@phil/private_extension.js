// Retype the selection in the other keyboard layout: select "ghbdtn", press
// Super+R, and it switches to ru and types "привет" over it.
//
// Works like `DOTOOL_XKB_LAYOUT=us dotool`: for each character it finds the
// key that typed it in its layout, then presses the same keys in the other
// layout. Keys come from gnome-shell's own virtual keyboard, so nothing needs
// /dev/uinput. Key tables come from `xkbcli compile-keymap` (libxkbcommon),
// which reads ~/.config/xkb as GNOME does.
//
// It types whatever the primary selection holds. With nothing selected now,
// that is the last selection anywhere, inserted at the cursor.
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import St from 'gi://St';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {getInputSourceManager} from 'resource:///org/gnome/shell/ui/status/keyboard.js';

import {keyTable, plan} from './keymap.js';

const ACCELERATOR = '<Super>r';
const MAX_LENGTH = 1000;
const KEY_LEFTSHIFT = 42; // evdev code
const HELD = Clutter.ModifierType.SHIFT_MASK | Clutter.ModifierType.CONTROL_MASK |
    Clutter.ModifierType.MOD1_MASK | Clutter.ModifierType.MOD4_MASK |
    Clutter.ModifierType.SUPER_MASK | Clutter.ModifierType.HYPER_MASK |
    Clutter.ModifierType.META_MASK;

export default class LayoutRetypeExtension extends Extension {
    enable() {
        this._tables = new Map();
        this._timeouts = new Set();
        this._busy = false;
        this._keyboard = Clutter.get_default_backend().get_default_seat()
            .create_virtual_device(Clutter.InputDeviceType.KEYBOARD_DEVICE);

        this._action = global.display.grab_accelerator(ACCELERATOR, Meta.KeyBindingFlags.NONE);
        if (this._action === Meta.KeyBindingAction.NONE) {
            console.error(`layout-retype: could not grab ${ACCELERATOR}`);
            return;
        }
        this._bindingName = Meta.external_binding_name_for_action(this._action);
        Main.wm.allowKeybinding(this._bindingName, Shell.ActionMode.NORMAL);
        this._accelId = global.display.connect('accelerator-activated', (_d, action) => {
            if (action === this._action)
                this._retype();
        });
    }

    disable() {
        if (this._accelId)
            global.display.disconnect(this._accelId);
        if (this._action !== Meta.KeyBindingAction.NONE) {
            global.display.ungrab_accelerator(this._action);
            Main.wm.allowKeybinding(this._bindingName, Shell.ActionMode.NONE);
        }
        for (const id of this._timeouts)
            GLib.source_remove(id);
        this._timeouts = null;
        this._tables = null;
        this._keyboard = null;
        this._accelId = null;
        this._action = null;
    }

    async _retype() {
        if (this._busy)
            return;
        this._busy = true;
        try {
            await this._run();
        } catch (e) {
            console.error(`layout-retype: ${e.message}`);
            Main.notify('Layout retype', e.message);
        } finally {
            this._busy = false;
        }
    }

    async _run() {
        const text = await new Promise(resolve => St.Clipboard.get_default()
            .get_text(St.ClipboardType.PRIMARY, (_c, t) => resolve(t)));
        if (!text)
            return;
        if (text.length > MAX_LENGTH)
            throw new Error(`Selection is longer than ${MAX_LENGTH} characters`);

        const ism = getInputSourceManager();
        const sources = Object.values(ism.inputSources)
            .filter(s => s.type === 'xkb')
            .sort((a, b) => a.index - b.index);
        if (sources.length < 2)
            throw new Error('Needs at least two keyboard layouts');
        const tables = await Promise.all(sources.map(s => this._table(s.id)));

        const current = Math.max(0, sources.indexOf(ism.currentSource));
        const {from, to, keys, missing} = plan(text, tables, current);
        if (!keys) {
            throw new Error(`"${missing}" is on neither ` +
                `${sources[from].shortName} nor ${sources[to].shortName}`);
        }

        // The shortcut's own keys must be up, or apps see Super+letters.
        if (!await this._modifiersReleased())
            throw new Error('Modifier keys are still held');
        await this._activate(sources[to]);
        if (!this._keyboard)
            return;

        const key = (code, pressed) => this._keyboard.notify_key(GLib.get_monotonic_time(),
            code, pressed ? Clutter.KeyState.PRESSED : Clutter.KeyState.RELEASED);
        for (const {code, shift} of keys) {
            if (shift)
                key(KEY_LEFTSHIFT, true);
            key(code, true);
            key(code, false);
            if (shift)
                key(KEY_LEFTSHIFT, false);
        }
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
