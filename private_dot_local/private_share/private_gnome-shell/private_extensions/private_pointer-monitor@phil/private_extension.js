// Wayland gives scripts no way to ask where the pointer is, so expose it:
//   busctl --user call org.gnome.Shell /org/gnome/Shell/Extensions/PointerMonitor \
//     org.gnome.Shell.Extensions.PointerMonitor GetConnectors
//   -> as 1 "DP-1"   (several when mirrored)
import Gio from 'gi://Gio';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.PointerMonitor">
    <method name="GetConnectors">
      <arg type="as" direction="out" name="connectors"/>
    </method>
  </interface>
</node>`;

export default class PointerMonitorExtension extends Extension {
    enable() {
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/PointerMonitor');
    }

    disable() {
        this._dbus.unexport();
        this._dbus = null;
    }

    GetConnectors() {
        const index = global.display.get_current_monitor();
        const logical = global.backend.get_monitor_manager().get_logical_monitors()
            .find(m => m.get_number() === index);
        return logical ? logical.get_monitors().map(m => m.get_connector()) : [];
    }
}
