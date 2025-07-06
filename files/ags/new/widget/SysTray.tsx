import Tray from 'gi://AstalTray';
import { Gtk } from 'ags/gtk4';
import { createWidgetContainer } from './WidgetContainer';

export default function SysTray() {
  const tray = Tray.get_default();

  // Map to track active popovers for each tray item
  const activePopovers = new Map();

  for (const item of tray.get_items()) {
    // Handle missing or empty titles
    const title = item.title || item.id || 'Unknown App';
    console.log(title);
  }

  function widgetFor(item: Tray.TrayItem) {
    const icon = item.get_gicon();
    if (icon) {
      const image = new Gtk.Image({
        gicon: icon,
        pixel_size: 16,
        css_classes: ['widget'],
      });

      const container = createWidgetContainer(image, {
        onLeftClick: (x, y) => {
          item.activate(x, y);
          const title = item.title || item.id || 'Unknown App';
          console.log(`Activated: ${title} at (${x},${y})`);
        },
        onRightClick: (x, y) => {
          const title = item.title || item.id || 'Unknown App';
          console.log(`Right click on: ${title}`);

          // Check if there's already an active popover for this item
          const existingPopover = activePopovers.get(item);
          if (existingPopover) {
            // If popover exists and is visible, close it
            if (existingPopover.get_visible()) {
              existingPopover.popdown();
              activePopovers.delete(item);
              console.log(`Closed existing popover for: ${title}`);
              return;
            } else {
              // If popover exists but not visible, clean it up
              activePopovers.delete(item);
            }
          }

          try {
            item.about_to_show();
            const menuModel = item.get_menu_model();
            if (menuModel) {
              const contextMenu = new Gtk.PopoverMenu({
                menu_model: menuModel,
              });

              // Store the popover so we can track it
              activePopovers.set(item, contextMenu);

              // Clean up when popover is closed
              contextMenu.connect('closed', () => {
                activePopovers.delete(item);
                console.log(`Popover closed for: ${title}`);
              });

              try {
                const actionGroup = item.get_action_group();
                if (actionGroup) {
                  contextMenu.insert_action_group('dbusmenu', actionGroup);
                  console.log(`Action group 'dbusmenu' inserted for: ${title}`);
                }
              } catch (e) {
                console.log(`get_action_group failed for: ${title}`, e);
              }

              try {
                if (item.action_group) {
                  contextMenu.insert_action_group('app', item.action_group);
                  console.log(
                    `Direct action group 'app' inserted for: ${title}`
                  );
                }
              } catch (e) {
                console.log(
                  `Direct action_group access failed for: ${title}`,
                  e
                );
              }

              contextMenu.set_parent(container);
              contextMenu.popup();
              console.log(`Menu model menu opened for: ${title}`);
              return;
            }

            // Fallback if no menu model
            item.secondary_activate(x, y);
            console.log(`Secondary activated: ${title} at (${x},${y})`);
          } catch (error) {
            console.log(`All menu methods failed for: ${title}, error:`, error);
            try {
              item.secondary_activate(x, y);
            } catch (e) {
              console.log(`Even secondary_activate failed for: ${title}`, e);
            }
          }
        },
      });

      return container;
    }

    // Handle missing title in fallback label too
    const title = item.title || item.id || 'Unknown App';
    return new Gtk.Label({ label: title });
  }

  const widget = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: ['widget'],
  });

  function rebuild() {
    // Clean up any active popovers when rebuilding
    activePopovers.forEach((popover, item) => {
      if (popover.get_visible()) {
        popover.popdown();
      }
    });
    activePopovers.clear();

    let child = widget.get_first_child();
    while (child) {
      widget.remove(child);
      child = widget.get_first_child();
    }
    for (const item of tray.get_items()) {
      widget.append(widgetFor(item));
    }
  }

  tray.connect('item-added', rebuild);
  tray.connect('item-removed', rebuild);
  rebuild();

  return widget;
}
