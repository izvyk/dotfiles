// Light bar: a Quick Settings tile for the Yeelight Screen Light Bar Pro on
// the Dell. The tile turns "wall light" on: the rear RGB light follows the
// top half of that monitor, split into left and right, one colour per side
// of the bar, 30 times a second (off after login; kept across the lock
// screen). Its menu has the rear brightness and the front (desk) light:
// on/off, brightness and colour temperature. The tile is hidden while the
// lamp doesn't answer (away from home), checked after network changes. The
// check talks to the lamp: a DNS lookup can be answered from the cache of
// the previous network.
//
// Capture: the stage paints that area at about 1/20 size into a texture, as
// GNOME's own screenshot keybinding does, so there's no ScreenCast portal and
// no screen-sharing indicator.
//
// Lamp (lamp15, fw 38, measured 2026-11-09):
//   * colour frames go over the undocumented UDP session on port 55444:
//     udp_sess_new -> {"method":"udp_sess_token","params":{"token":...}},
//     then set_segment_rgb [left, right] with that token, no rate limit
//     (music mode doesn't exist on this model);
//   * everything else goes over the TCP API on 55443, ~60 commands/minute;
//     front light: set_power, set_bright, set_ct_abx (2700-6500 K); rear:
//     bg_set_power, bg_set_bright;
//   * for about a second after every colour frame the lamp answers "ok" to
//     TCP commands but ignores them (front light included), so the stream is
//     held for POWER_LOCK_MS before each batch of commands;
//   * brightness and temperature are ignored (with "ok") while that light
//     is off, so desk sliders switch the desk light on, and a wall brightness
//     set while the wall light is off waits for it to come on;
//   * a segment colour carries hue and saturation only (0x010000 is full
//     red); brightness is the rear light's own bg_bright, so a dark side is
//     switched off instead of dimmed.
// Both directions are started from here, so no firewall port is needed.
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import Mtk from 'gi://Mtk';
import Shell from 'gi://Shell';
import St from 'gi://St';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {QuickMenuToggle, SystemIndicator} from 'resource:///org/gnome/shell/ui/quickSettings.js';
import {Slider} from 'resource:///org/gnome/shell/ui/slider.js';

// DHCP name from the router (derived from the MAC, so it survives a lamp
// reset); resolved again for every new UDP session.
const LAMP_HOST = 'yeelink-light-lamp15_miapD41B.lan';
const TCP_PORT = 55443;
const UDP_PORT = 55444;
const MONITOR_PRODUCT = 'DELL S2725QC'; // the monitor the bar sits on
const CT_MIN = 2700; // front light colour temperature range, K
const CT_MAX = 6500;
const FPS = 30;
const CAPTURE_WIDTH = 128; // pixels across the captured strip
const SMOOTHING_S = 0.12; // time constant of the colour fade
const SATURATION = 1.3; // averages come out washed-out; push them a bit
const DARK = 0.04; // luma (0-1) below which a side goes dark...
const WAKE = 0.06; // ...and above which it lights again
const KEEPALIVE_S = 5;
const SESSION_TIMEOUT_S = 16; // no reply for this long (keepalives are answered): new session
const SESSION_RETRY_S = 2;
const POWER_LOCK_MS = 1300; // the lamp ignores TCP commands ~1 s after a frame
const COMMAND_GAP_MS = 250; // between TCP commands, so a slider drag stays under the quota
const NETWORK_SETTLE_MS = 2000;
// At home the lamp answers in well under a second; away, the DNS lookup
// through Tailscale takes 10-15 s to fail.
const CHECK_TIMEOUT_MS = 4000;
const ICON = 'display-brightness-symbolic';
const DEBUG = false;

Gio._promisify(Gio.SocketClient.prototype, 'connect_to_host_async');
Gio._promisify(Gio.OutputStream.prototype, 'write_bytes_async');
Gio._promisify(Gio.DataInputStream.prototype, 'read_line_async');
Gio._promisify(Gio.Resolver.prototype, 'lookup_by_name_async');
Gio._promisify(Shell.Screenshot, 'composite_to_stream');

const encoder = new TextEncoder();
const decoder = new TextDecoder();

function debug(message) {
    if (DEBUG)
        console.log(`wall-light: ${message}`);
}

function sleep(ms) {
    return new Promise(resolve => GLib.timeout_add(GLib.PRIORITY_DEFAULT, Math.max(0, ms), () => {
        resolve();
        return GLib.SOURCE_REMOVE;
    }));
}

function nowMs() {
    return GLib.get_monotonic_time() / 1000;
}

// One command over TCP; resolves with the reply's result array.
async function tcpCall(method, params, cancellable = null) {
    const client = new Gio.SocketClient({timeout: 3});
    const conn = await client.connect_to_host_async(LAMP_HOST, TCP_PORT, cancellable);
    try {
        const request = JSON.stringify({id: 1, method, params});
        await conn.get_output_stream().write_bytes_async(
            new GLib.Bytes(encoder.encode(`${request}\r\n`)), GLib.PRIORITY_DEFAULT, null);
        const input = new Gio.DataInputStream({base_stream: conn.get_input_stream()});
        for (;;) { // property notifications may come first
            const [line] = await input.read_line_async(GLib.PRIORITY_DEFAULT, null);
            if (line === null)
                throw new Error(`${method}: connection closed`);
            const text = decoder.decode(line).trim();
            if (!text.startsWith('{"id"'))
                continue;
            debug(`tcp ${method} ${JSON.stringify(params)} -> ${text}`);
            const reply = JSON.parse(text);
            if (reply.error)
                throw new Error(`${method}: ${reply.error.message}`);
            return reply.result;
        }
    } finally {
        conn.close(null);
    }
}

// The UDP session. Driven from the frame timer: no socket sources, so nothing
// outlives stop().
class Session {
    constructor() {
        this._address = null;
        this._resolving = false;
        this._closed = false;
        this._socket = Gio.Socket.new(Gio.SocketFamily.IPV4,
            Gio.SocketType.DATAGRAM, Gio.SocketProtocol.UDP);
        this._socket.set_blocking(false);
        this._token = null;
        this._id = 1;
        this._asked = -Infinity;
        this._keptAlive = 0;
        this._heard = 0;
    }

    close() {
        this._closed = true;
        this._socket.close();
    }

    // Reads replies, opens the session and keeps it alive. Returns whether
    // frames can be sent.
    poll(now) {
        while (this._socket.condition_check(GLib.IOCondition.IN) & GLib.IOCondition.IN) {
            let bytes;
            try {
                bytes = this._socket.receive_bytes(4096, 0, null);
            } catch {
                break;
            }
            this._heard = now;
            for (const line of decoder.decode(bytes.toArray()).split('\r\n')) {
                if (!line)
                    continue;
                debug(`udp <- ${line.replace(/"token":"[^"]*"/, '"token":"..."')}`);
                try {
                    const reply = JSON.parse(line);
                    if (reply.method === 'udp_sess_token') {
                        this._token = reply.params?.token ?? null;
                        this._keptAlive = now;
                    } else if (reply.error && this._token) {
                        this._token = null; // lamp restarted or session expired
                    }
                } catch {}
            }
        }
        if (this._token && now - this._heard >= SESSION_TIMEOUT_S)
            this._token = null; // lamp restarted or the network dropped
        if (!this._token) {
            if (now - this._asked >= SESSION_RETRY_S) {
                this._asked = now;
                this._ask();
            }
            return false;
        }
        if (now - this._keptAlive >= KEEPALIVE_S) {
            this._keptAlive = now;
            this._send({id: this._nextId(), method: 'udp_sess_keep_alive',
                params: ['keeplive_interval', '10'], token: this._token});
        }
        return true;
    }

    async _ask() {
        if (this._resolving)
            return;
        this._resolving = true;
        try {
            const addresses = await Gio.Resolver.get_default().lookup_by_name_async(LAMP_HOST, null);
            const address = addresses.find(a => a.get_family() === Gio.SocketFamily.IPV4);
            if (!address)
                throw new Error(`no IPv4 address for ${LAMP_HOST}`);
            if (this._closed)
                return;
            this._address = new Gio.InetSocketAddress({address, port: UDP_PORT});
            this._send({id: 1, method: 'udp_sess_new', params: []});
        } catch (e) {
            debug(`resolve: ${e.message}`); // retried after SESSION_RETRY_S
        } finally {
            this._resolving = false;
        }
    }

    frame(left, right) {
        this._send({id: this._nextId(), method: 'set_segment_rgb',
            params: [left, right], token: this._token});
    }

    _nextId() {
        this._id = this._id % 1000000 + 1;
        return this._id;
    }

    _send(message) {
        try {
            this._socket.send_to(this._address, encoder.encode(`${JSON.stringify(message)}\r\n`), null);
        } catch (e) {
            debug(`udp send: ${e.message}`); // network down; the timer retries
        }
    }
}

// Average colour of the left and right half of a pixbuf, as 0-255 RGB triples.
function halves(pixbuf) {
    const width = pixbuf.get_width();
    const height = pixbuf.get_height();
    const stride = pixbuf.get_rowstride();
    const channels = pixbuf.get_n_channels();
    const pixels = pixbuf.read_pixel_bytes().toArray();
    const middle = Math.floor(width / 2);
    const sums = [[0, 0, 0], [0, 0, 0]];
    for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
            const i = y * stride + x * channels;
            const sum = sums[x < middle ? 0 : 1];
            sum[0] += pixels[i];
            sum[1] += pixels[i + 1];
            sum[2] += pixels[i + 2];
        }
    }
    return [
        sums[0].map(v => v / (middle * height)),
        sums[1].map(v => v / ((width - middle) * height)),
    ];
}

// Full-value colour with boosted saturation, as an 0xRRGGBB integer.
function lampColor([r, g, b]) {
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    if (max <= 0)
        return 0;
    const saturation = (max - min) / max;
    const boost = saturation > 0 ? Math.min(1, saturation * SATURATION) / saturation : 1;
    const channel = v => Math.round(255 * (1 - (1 - v / max) * boost));
    return (channel(r) << 16) | (channel(g) << 8) | channel(b);
}

function findMonitor() {
    const manager = global.backend.get_monitor_manager();
    const monitor = manager.get_monitors().find(m => m.get_product() === MONITOR_PRODUCT);
    if (!monitor)
        return null;
    const index = manager.get_monitor_for_connector(monitor.get_connector());
    return Main.layoutManager.monitors[index] ?? null;
}

// Brightness 1-100 <-> slider 0-1.
const toBright = value => Math.round(1 + value * 99);
const fromBright = bright => (bright - 1) / 99;
const toCt = value => Math.round((CT_MIN + value * (CT_MAX - CT_MIN)) / 100) * 100;
const fromCt = ct => (ct - CT_MIN) / (CT_MAX - CT_MIN);

// A label row and a slider row, as GNOME's own brightness menu does.
// onChange gets the value only for user changes, not for set().
function addSlider(menu, label, onChange) {
    menu.addMenuItem(new PopupMenu.PopupMenuItem(label, {reactive: false}));
    const slider = new Slider(0);
    slider.accessible_name = label;
    const item = new PopupMenu.PopupBaseMenuItem({reactive: false});
    item.add_child(new St.Bin({
        style_class: 'slider-bin',
        child: slider,
        reactive: true,
        can_focus: true,
        x_expand: true,
        y_align: Clutter.ActorAlign.CENTER,
    }));
    menu.addMenuItem(item);
    let updating = false;
    slider.connect('notify::value', () => {
        if (!updating)
            onChange(slider.value);
    });
    return {
        set(value) {
            updating = true;
            slider.value = Math.min(1, Math.max(0, value));
            updating = false;
        },
    };
}

const LightBarToggle = GObject.registerClass(
class LightBarToggle extends QuickMenuToggle {
    _init(extension) {
        super._init({
            title: 'Wall Light',
            iconName: ICON,
            toggleMode: true,
            menuButtonAccessibleName: 'Open light bar menu',
        });
        this.menu.setHeader(ICON, 'Light Bar');

        this._rearBright = addSlider(this.menu, 'Wall brightness',
            v => extension.setRearBrightness(toBright(v)));

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._deskSwitch = new PopupMenu.PopupSwitchMenuItem('Desk light', false);
        this._deskSwitch.connect('toggled', (_item, on) =>
            extension.command('set_power', [on ? 'on' : 'off', 'smooth', 300]));
        this.menu.addMenuItem(this._deskSwitch);
        // Moving a desk slider switches the desk light on.
        const deskOn = () => {
            if (!this._deskSwitch.state) {
                this._deskSwitch.setToggleState(true);
                extension.command('set_power', ['on', 'smooth', 300]);
            }
        };
        this._deskBright = addSlider(this.menu, 'Desk brightness', v => {
            deskOn();
            extension.command('set_bright', [toBright(v), 'smooth', 200]);
        });
        this._deskCt = addSlider(this.menu, 'Desk temperature', v => {
            deskOn();
            extension.command('set_ct_abx', [toCt(v), 'smooth', 200]);
        });

        this.menu.connect('open-state-changed', (_menu, open) => {
            if (open)
                this._refresh(extension);
        });
    }

    async _refresh(extension) {
        try {
            const [mainPower, bright, ct, bgBright] =
                await tcpCall('get_prop', ['main_power', 'bright', 'ct', 'bg_bright']);
            this._deskSwitch.setToggleState(mainPower === 'on');
            this._deskBright.set(fromBright(Number(bright)));
            this._deskCt.set(fromCt(Number(ct)));
            this._rearBright.set(fromBright(extension.pendingRearBrightness ?? Number(bgBright)));
            this.menu.setHeader(ICON, 'Light Bar');
        } catch (e) {
            debug(`refresh: ${e.message}`);
            this.menu.setHeader(ICON, 'Light Bar', 'Not responding');
        }
    }
});

const LightBarIndicator = GObject.registerClass(
class LightBarIndicator extends SystemIndicator {
    _init(extension) {
        super._init();
        this.toggle = new LightBarToggle(extension);
        this.quickSettingsItems.push(this.toggle);
    }
});

export default class WallLightExtension extends Extension {
    enable() {
        // This object lives until logout, so _wanted survives the lock screen
        // (which disables extensions).
        this._wanted ??= false;
        this._available = false;
        this._checkedOnce = false;
        this._running = false;
        this._generation ??= 0;
        // The command queue may still be sending the rear light off from
        // before the lock screen; keep it.
        this._pending ??= new Map();
        this._flushing ??= null;
        this._hold ??= false;
        this._lastFrameMs ??= -Infinity;

        this._indicator = new LightBarIndicator(this);
        this._toggle = this._indicator.toggle;
        this._toggle.visible = false;
        this._toggle.checked = this._wanted;
        this._toggle.connect('notify::checked', toggle => {
            this._wanted = toggle.checked;
            this._sync();
        });
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);

        this._monitorsChangedId = Main.layoutManager.connect('monitors-changed', () => this._sync());
        this._networkChangedId = Gio.NetworkMonitor.get_default().connect('network-changed', () => {
            if (this._networkTimer)
                GLib.source_remove(this._networkTimer);
            debug('network changed');
            this._networkTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, NETWORK_SETTLE_MS, () => {
                this._networkTimer = 0;
                this._checkLamp();
                return GLib.SOURCE_REMOVE;
            });
        });
        this._checkLamp();
    }

    disable() {
        Main.layoutManager.disconnect(this._monitorsChangedId);
        Gio.NetworkMonitor.get_default().disconnect(this._networkChangedId);
        if (this._networkTimer) {
            GLib.source_remove(this._networkTimer);
            this._networkTimer = 0;
        }
        this._stop(); // queues the rear light off; the queue finishes on its own
        this._indicator.quickSettingsItems.forEach(item => item.destroy());
        this._indicator.destroy();
        this._indicator = null;
        this._toggle = null;
    }

    // Shows the tile only while the lamp answers (at home).
    async _checkLamp() {
        // A failing lookup can take 15 s; a change during it gets its own
        // check afterwards.
        if (this._checking) {
            this._recheck = true;
            return;
        }
        this._checking = true;
        let available = false;
        const cancellable = new Gio.Cancellable();
        const timeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, CHECK_TIMEOUT_MS, () => {
            cancellable.cancel();
            return GLib.SOURCE_REMOVE;
        });
        try {
            await tcpCall('get_prop', ['power'], cancellable);
            available = true;
        } catch (e) {
            debug(`check: ${e.message}`);
        } finally {
            if (!cancellable.is_cancelled())
                GLib.source_remove(timeout);
            this._checking = false;
        }
        if (this._recheck) {
            this._recheck = false;
            this._checkLamp();
            return;
        }
        if (!this._toggle || available === this._available && this._checkedOnce)
            return;
        this._checkedOnce = true;
        debug(`lamp ${available ? 'found' : 'not found'}`);
        this._available = available;
        this._toggle.visible = available;
        if (!available)
            this._toggle.menu.close();
        this._sync();
    }

    _sync() {
        const monitor = findMonitor();
        this._toggle.subtitle = monitor ? null : 'Monitor not connected';
        if (this._wanted && monitor && this._available)
            this._start(monitor).catch(e => console.error(`wall-light: ${e.message}`));
        else
            this._stop();
    }

    // Queues a TCP command; a newer one with the same method replaces it
    // (slider drags). While frames stream, they're held long enough for the
    // lamp to listen again.
    command(method, params) {
        this._pending.delete(method);
        this._pending.set(method, params);
        this._flushing ??= this._flush().finally(() => {
            this._flushing = null;
        });
        return this._flushing;
    }

    setRearBrightness(bright) {
        if (this._running) {
            this.command('bg_set_bright', [bright, 'smooth', 200]);
        } else {
            this.pendingRearBrightness = bright;
        }
    }

    async _flush() {
        try {
            while (this._pending.size) {
                this._hold = true;
                await sleep(this._lastFrameMs + POWER_LOCK_MS - nowMs());
                const [method, params] = this._pending.entries().next().value;
                this._pending.delete(method);
                try {
                    await tcpCall(method, params);
                } catch (e) {
                    console.warn(`wall-light: ${e.message}`);
                }
                if (this._pending.size)
                    await sleep(COMMAND_GAP_MS);
            }
        } finally {
            this._hold = false;
        }
    }

    async _start(monitor) {
        this._monitor = monitor; // also picks up geometry changes while running
        if (this._running)
            return;
        this._running = true;
        const generation = ++this._generation;

        const ready = this.command('bg_set_power', ['on', 'smooth', 300]);
        if (this.pendingRearBrightness) {
            this.command('bg_set_bright', [this.pendingRearBrightness, 'sudden', 0]);
            this.pendingRearBrightness = null;
        }
        await ready;
        if (generation !== this._generation)
            return;

        this._session = new Session();
        this._smoothed = null;
        this._busy = false;
        this._timer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, Math.round(1000 / FPS), () => {
            this._tick();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _stop() {
        if (!this._running)
            return;
        this._running = false;
        this._generation++;
        if (this._timer) {
            GLib.source_remove(this._timer);
            this._timer = 0;
        }
        this._session?.close();
        this._session = null;
        this.command('bg_set_power', ['off', 'smooth', 500]);
    }

    _tick() {
        if (this._hold)
            return;
        const now = GLib.get_monotonic_time() / 1e6;
        if (!this._session.poll(now) || this._busy)
            return;

        const {x, y, width, height} = this._monitor;
        let content;
        try {
            content = global.stage.paint_to_content(
                new Mtk.Rectangle({x, y, width, height: Math.floor(height / 2)}),
                CAPTURE_WIDTH / width, null, Clutter.PaintFlag.NO_CURSORS);
        } catch (e) {
            debug(`paint: ${e.message}`);
            return;
        }
        if (!content)
            return;

        this._busy = true;
        const session = this._session;
        Shell.Screenshot.composite_to_stream(content.get_texture(), 0, 0, -1, -1, 1,
            null, 0, 0, 1, Gio.MemoryOutputStream.new_resizable())
            .then(pixbuf => {
                if (session === this._session && !this._hold)
                    this._send(halves(pixbuf), now);
            })
            .catch(e => debug(`capture: ${e.message}`))
            .finally(() => {
                this._busy = false;
            });
    }

    _send(means, now) {
        // Exponential fade towards the new averages.
        const alpha = this._smoothed ? 1 - Math.exp(-(now - this._smoothedAt) / SMOOTHING_S) : 1;
        this._smoothed ??= means.map(() => ({rgb: [0, 0, 0], dark: true}));
        this._smoothedAt = now;
        const colors = this._smoothed.map((side, i) => {
            side.rgb = side.rgb.map((v, c) => v + alpha * (means[i][c] - v));
            const [r, g, b] = side.rgb;
            const luma = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
            side.dark = luma < (side.dark ? WAKE : DARK);
            return side.dark ? 0 : lampColor(side.rgb);
        });
        this._session.frame(colors[0], colors[1]);
        this._lastFrameMs = nowMs();
        debug(`frame ${colors.map(c => c.toString(16).padStart(6, '0')).join(' ')}`);
    }
}
