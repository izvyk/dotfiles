// Wall light: the rear RGB light of the Yeelight Screen Light Bar Pro on the
// Dell follows the screen. The top half of that monitor is split into left
// and right; each half's average colour goes to the bar's segment on that
// side, 30 times a second. Toggle in Quick Settings (off after login; kept
// across the lock screen).
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
//   * power and brightness go over the TCP API on 55443, ~60 commands/minute;
//   * a segment colour carries hue and saturation only (0x010000 is full
//     red). Brightness is the global bg_bright, which the lamp ignores for
//     about a second after every frame, so it's set once before streaming,
//     and a dark side is switched off instead of dimmed.
// Both directions are started from here, so no firewall port is needed.
import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import Mtk from 'gi://Mtk';
import Shell from 'gi://Shell';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {QuickToggle, SystemIndicator} from 'resource:///org/gnome/shell/ui/quickSettings.js';

// DHCP name from the router (derived from the MAC, so it survives a lamp
// reset); resolved again for every new UDP session.
const LAMP_HOST = 'yeelink-light-lamp15_miapD41B.lan';
const TCP_PORT = 55443;
const UDP_PORT = 55444;
const MONITOR_PRODUCT = 'DELL S2725QC'; // the monitor the bar sits on
const BRIGHTNESS = 70; // rear light, 1-100, fixed while streaming
const FPS = 30;
const CAPTURE_WIDTH = 128; // pixels across the captured strip
const SMOOTHING_S = 0.12; // time constant of the colour fade
const SATURATION = 1.3; // averages come out washed-out; push them a bit
const DARK = 0.04; // luma (0-1) below which a side goes dark...
const WAKE = 0.06; // ...and above which it lights again
const KEEPALIVE_S = 5;
const SESSION_TIMEOUT_S = 16; // no reply for this long (keepalives are answered): new session
const SESSION_RETRY_S = 2;
const POWER_LOCK_MS = 1300; // the lamp ignores power commands ~1 s after a frame
const DEBUG = false;

Gio._promisify(Gio.SocketClient.prototype, 'connect_to_host_async');
Gio._promisify(Gio.OutputStream.prototype, 'write_bytes_async');
Gio._promisify(Gio.DataInputStream.prototype, 'read_line_async');
Gio._promisify(Shell.Screenshot, 'composite_to_stream');
Gio._promisify(Gio.Resolver.prototype, 'lookup_by_name_async');

const encoder = new TextEncoder();
const decoder = new TextDecoder();

function debug(message) {
    if (DEBUG)
        console.log(`wall-light: ${message}`);
}

// One command over TCP; resolves with the reply line.
async function tcpCall(method, params) {
    const client = new Gio.SocketClient({timeout: 3});
    const conn = await client.connect_to_host_async(LAMP_HOST, TCP_PORT, null);
    try {
        const request = JSON.stringify({id: 1, method, params});
        await conn.get_output_stream().write_bytes_async(
            new GLib.Bytes(encoder.encode(`${request}\r\n`)), GLib.PRIORITY_DEFAULT, null);
        const input = new Gio.DataInputStream({base_stream: conn.get_input_stream()});
        for (;;) { // property notifications may come first
            const [line] = await input.read_line_async(GLib.PRIORITY_DEFAULT, null);
            if (line === null)
                throw new Error(`${method}: connection closed`);
            const reply = decoder.decode(line).trim();
            if (reply.startsWith('{"id"')) {
                debug(`tcp ${method} -> ${reply}`);
                if (reply.includes('"error"'))
                    throw new Error(`${method}: ${reply}`);
                return reply;
            }
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

// Average colour of the left and right half of a pixbuf, as linear-ish
// 0-255 RGB triples.
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

const WallLightToggle = GObject.registerClass(
class WallLightToggle extends QuickToggle {
    _init() {
        super._init({
            title: 'Wall Light',
            iconName: 'display-brightness-symbolic',
            toggleMode: true,
        });
    }
});

const WallLightIndicator = GObject.registerClass(
class WallLightIndicator extends SystemIndicator {
    _init() {
        super._init();
        this.toggle = new WallLightToggle();
        this.quickSettingsItems.push(this.toggle);
    }
});

export default class WallLightExtension extends Extension {
    enable() {
        // This object lives until logout, so _wanted survives the lock screen
        // (which disables extensions).
        this._wanted ??= false;
        this._running = false;
        this._generation = 0;
        this._indicator = new WallLightIndicator();
        this._indicator.toggle.checked = this._wanted;
        this._indicator.toggle.connect('notify::checked', toggle => {
            this._wanted = toggle.checked;
            this._sync();
        });
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
        this._monitorsChangedId = Main.layoutManager.connect('monitors-changed', () => this._sync());
        this._sync();
    }

    disable() {
        Main.layoutManager.disconnect(this._monitorsChangedId);
        this._stop();
        this._indicator.quickSettingsItems.forEach(item => item.destroy());
        this._indicator.destroy();
        this._indicator = null;
    }

    _sync() {
        const monitor = findMonitor();
        this._indicator.toggle.subtitle = monitor ? null : 'Monitor not connected';
        if (this._wanted && monitor)
            this._start(monitor).catch(e => console.error(`wall-light: ${e.message}`));
        else
            this._stop();
    }

    async _start(monitor) {
        this._monitor = monitor; // also picks up geometry changes while running
        if (this._running)
            return;
        this._running = true;
        const generation = ++this._generation;
        if (this._offTimer) {
            GLib.source_remove(this._offTimer);
            this._offTimer = 0;
        }

        // Brightness has to land before the first frame, or the lamp drops it.
        try {
            await tcpCall('bg_set_power', ['on', 'smooth', 300]);
            await tcpCall('bg_set_bright', [BRIGHTNESS, 'sudden', 0]);
        } catch (e) {
            console.warn(`wall-light: ${e.message}`); // stream anyway; the lamp may be on already
        }
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
        this._offTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, POWER_LOCK_MS, () => {
            this._offTimer = 0;
            tcpCall('bg_set_power', ['off', 'smooth', 500])
                .catch(e => console.warn(`wall-light: ${e.message}`));
            return GLib.SOURCE_REMOVE;
        });
    }

    _tick() {
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
                if (session === this._session)
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
        debug(`frame ${colors.map(c => c.toString(16).padStart(6, '0')).join(' ')}`);
    }
}
