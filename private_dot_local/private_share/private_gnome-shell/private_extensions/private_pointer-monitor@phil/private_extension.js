// What scripts can't do themselves on Wayland: ask where the pointer is, and
// show GNOME's own OSD (org.gnome.Shell.ShowOSD is only open to GNOME itself).
//   busctl --user call org.gnome.Shell /org/gnome/Shell/Extensions/PointerMonitor \
//     org.gnome.Shell.Extensions.PointerMonitor GetConnectors
//   -> as 1 "DP-1"   (several when mirrored)
//   ... ShowOsd sd display-brightness-symbolic 0.45   (level from 0 to 1, on the
//   monitor under the pointer)
import Gio from 'gi://Gio';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.PointerMonitor">
    <method name="GetConnectors">
      <arg type="as" direction="out" name="connectors"/>
    </method>
    <method name="ShowOsd">
      <arg type="s" direction="in" name="icon"/>
      <arg type="d" direction="in" name="level"/>
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

    ShowOsd(iconName, level) {
        const icon = new Gio.ThemedIcon({name: iconName});
        const osd = Main.osdWindowManager;
        // GNOME 46 has show() with these arguments; newer ones call it showOne().
        (osd.showOne ?? osd.show).call(osd, global.display.get_current_monitor(), icon, undefined, level, 1);
    }
}
