import Tray from 'gi://AstalTray';
import { Gtk } from 'ags/gtk4';
import { createContainer } from '../../widget_helper/Container';
import {
  createSystemTrayPopoverMenu,
  cleanupAllPopovers,
} from '../../widget_helper/SharedPopoverMenu';

// debug helper – flip DEBUG to true for verbose output
const DEBUG = false;
const log = (...args: unknown[]) => {
  if (DEBUG) console.log(...args);
};

export default function SysTray() {
  const tray = Tray.get_default();
  for (const item of tray.get_items()) {
    const title = item.title || item.id || 'Unknown App';
    log(title);
  }

  function widgetFor(item: Tray.TrayItem) {
    const icon = item.get_gicon();
    if (icon) {
      const image = new Gtk.Image({
        gicon: icon,
        pixel_size: 16,
      });
      const container = createContainer(image, {
        onLeftClick: (x, y) => {
          item.activate(x, y);
          log(
            `Activated: ${item.title || item.id || 'Unknown App'} at (${x},${y})`
          );
        },
        onRightClick: (x, y) => {
          const title = item.title || item.id || 'Unknown App';
          log(`Right click on: ${title}`);
          createSystemTrayPopoverMenu(container, item, title);
          if (!item.get_menu_model()) {
            try {
              item.secondary_activate(x, y);
              log(`Secondary activated: ${title} at (${x},${y})`);
            } catch (error) {
              log(`All menu methods failed for: ${title}, error:`, error);
            }
          }
        },
      });
      return container;
    }
    const title = item.title || item.id || 'Unknown App';
    return new Gtk.Label({ label: title });
  }

  const widget = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: ['widget'],
  });

  function rebuild() {
    cleanupAllPopovers();
    let child = widget.get_first_child();
    while (child) {
      widget.remove(child);
      child = widget.get_first_child();
    }
    for (const item of tray.get_items()) widget.append(widgetFor(item));
  }

  tray.connect('item-added', rebuild);
  tray.connect('item-removed', rebuild);
  rebuild();
  return widget;
}
