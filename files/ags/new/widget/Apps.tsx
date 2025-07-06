import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import { createWidgetContainer } from './WidgetContainer';

let activePopover: Gtk.Popover | null = null;

function buildActionsBox(
  info: Gio.DesktopAppInfo,
  acts: string[],
  app: Apps.Application
): Gtk.Box {
  if (acts.length === 0) acts = ['__NEW_WINDOW__'];

  const box = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 4,
    margin_top: 4,
    margin_bottom: 4,
    margin_start: 6,
    margin_end: 6,
  });

  acts.forEach((id) => {
    const label =
      id === '__NEW_WINDOW__' ? 'New Window' : (info.get_action_name(id) ?? id);

    const btn = Gtk.Button.new_with_label(label);
    btn.connect('clicked', () => {
      if (id === '__NEW_WINDOW__') app.launch();
      else info.launch_action(id, null);

      activePopover?.popdown();
      activePopover = null;
    });
    box.append(btn);
  });

  return box;
}

function widgetForApp(app: Apps.Application): Gtk.Widget {
  const image = new Gtk.Image({
    icon_name: app.get_icon_name(),
    pixel_size: 32,
  });

  const container = createWidgetContainer(image, {
    onLeftClick: () => app.launch(),
    onRightClick: () => {
      GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
        if (activePopover) {
          activePopover.popdown();
          activePopover = null;
        }

        const info = Gio.DesktopAppInfo.new(app.get_entry());
        if (!info) return GLib.SOURCE_REMOVE;

        const acts = info.list_actions() ?? [];
        const pop = new Gtk.Popover({
          child: buildActionsBox(info, acts, app),
          autohide: true,
        });

        (pop as any).set_parent(container);
        pop.popup();
        activePopover = pop;

        return GLib.SOURCE_REMOVE;
      });
    },
  });

  return container;
}

function exactApp(name: string): Apps.Application {
  const apps = new Apps.Apps({
    nameMultiplier: 2,
    entryMultiplier: 0,
    executableMultiplier: 2,
  });
  for (const a of apps.exact_query(name)) return a;
  throw new Error(`App '${name}' not found`);
}

export default function AppsWidget() {
  const names = [
    'Files',
    'Firefox',
    'Discord',
    'Spotify',
    'Geary',
    'Calendar',
    'Terminal',
  ];

  return (
    <box orientation={Gtk.Orientation.HORIZONTAL} class="widget" spacing={8}>
      {names.map((n) => {
        try {
          return widgetForApp(exactApp(n));
        } catch {
          return (
            <box orientation={Gtk.Orientation.HORIZONTAL} class="app-entry">
              <label
                label={`Error: could not find app '${n}'`}
                cssName="error"
              />
            </box>
          );
        }
      })}
    </box>
  );
}
