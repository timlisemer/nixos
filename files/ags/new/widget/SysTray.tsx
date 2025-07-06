import Tray from 'gi://AstalTray';
import { Gtk } from 'ags/gtk4';
import { createWidgetContainer } from './WidgetContainer';

export default function SysTray() {
  const tray = Tray.get_default();

  for (const item of tray.get_items()) {
    console.log(item.title);
  }

  // helper to make one widget per tray item
  function widgetFor(item: Tray.TrayItem) {
    const icon = item.get_gicon();
    if (icon) {
      const image = new Gtk.Image({
        gicon: icon,
        pixel_size: 16,
        css_classes: ['widget'],
      });

      // build via shared helper
      return createWidgetContainer(image, {
        onLeftClick: (x, y) => {
          item.activate(x, y);
          console.log(`Activated: ${item.title} at (${x},${y})`);
        },
        onRightClick: (x, y) => {
          item.secondary_activate(x, y);
          console.log(`Secondary activated: ${item.title} at (${x},${y})`);
        },
      });
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
