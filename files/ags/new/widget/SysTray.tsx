import Tray from 'gi://AstalTray';
import { Gtk } from 'ags/gtk4';

export default function SysTray() {
  const tray = Tray.get_default();

  for (const item of tray.get_items()) {
    console.log(item.title);
  }
  // --------------------------------------------------------------------------

  // helper to make one widget per tray item
  function widgetFor(item: Tray.TrayItem) {
    const icon = item.get_gicon();
    if (icon) {
      // If the tray item has an icon, use it
      const image = new Gtk.Image({
        gicon: icon,
        pixel_size: 16, // reasonable icon size
        css_classes: ['widget'],
      });

      // GTK 4: wrap in a container and add GestureClick controllers
      const box = new Gtk.Box();
      box.append(image);

      // primary (left) click → activate at pointer coordinates
      const clickLeft = new Gtk.GestureClick({ button: 1 });
      clickLeft.connect('released', (gesture) => {
        const ev = gesture.get_current_event();
        if (ev) {
          const [ok, x, y] = ev.get_position();
          if (ok) {
            item.activate(x, y);
            console.log(`Activated: ${item.title} at (${x},${y})`);
          }
        }
      });
      box.add_controller(clickLeft);

      // secondary (right) click → secondaryActivate at pointer coordinates
      const clickRight = new Gtk.GestureClick({ button: 3 });
      clickRight.connect('released', (gesture) => {
        const ev = gesture.get_current_event();
        if (ev) {
          const [ok, x, y] = ev.get_position();
          if (ok) {
            item.secondary_activate(x, y);
            console.log(`Secondary activated: ${item.title} at (${x},${y})`);
          }
        }
      });
      box.add_controller(clickRight);

      // return the wrapper, not the plain image
      return box;
    }

    // If the tray item exposes a widget, use it; otherwise, fallback to a label
    return new Gtk.Label({ label: item.title });
  }

  // Create the widget (box) and populate it
  const widget = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: ['widget'],
  });

  function rebuild() {
    let child = widget.get_first_child();
    while (child) {
      widget.remove(child);
      child = widget.get_first_child();
    }
    for (const item of tray.get_items()) {
      widget.append(widgetFor(item));
    }
  }

  // Initial population and reactive updates
  tray.connect('item-added', rebuild);
  tray.connect('item-removed', rebuild);

  rebuild();

  return widget;
}
