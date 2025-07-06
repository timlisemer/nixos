import app from 'ags/gtk4/app';
import { Astal, Gdk, Gtk } from 'ags/gtk4'; // Gtk added for empty box
import { createContainer } from './Container'; // NEW – helper with click hooks

// Overview component
export default function Overview(gdkmonitor: Gdk.Monitor) {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  return (
    <window
      name="overview"
      class="Overview"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.IGNORE}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      application={app}
      visible={false}
    >
      {/* Ground layer: fills the entire screen, dark translucent background,
          closes overview on any click */}
      {createContainer(
        new Gtk.Box({ hexpand: true, vexpand: true }) /* empty child */,
        {
          widget: false, // do NOT add default 'widget' css
          overrideCss: ['overview'], // use .overview class for styling
          onLeftClick: () => {
            console.log('left click on overview');
            app.toggle_window('overview'); // close the overlay
          },
          onRightClick: () => {
            console.log('right click on overview');
            app.toggle_window('overview'); // close the overlay
          },
        }
      )}
    </window>
  );
}
