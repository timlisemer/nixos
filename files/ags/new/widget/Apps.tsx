import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import Gio from 'gi://Gio'; // ★ now needed for DesktopAppInfo
import { createWidgetContainer } from './WidgetContainer'; // (still used elsewhere)

// Keep a single popover alive so only one menu is ever open
let activePopover: Gtk.Popover | null = null; // ★

// helper: build a Popover listing desktop-file actions
function buildActionsPopover(
  info: Gio.DesktopAppInfo,
  acts: string[]
): Gtk.Popover {
  const list = new Gtk.Box({
    // vertical list of buttons
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 4,
    margin_top: 4,
    margin_bottom: 4,
    margin_start: 6,
    margin_end: 6,
  });

  acts.forEach((id) => {
    const btn = Gtk.Button.new_with_label(info.get_action_name(id) ?? id);
    btn.connect('clicked', () => {
      info.launch_action(id, null); // launch the chosen action
      activePopover?.popdown();
      activePopover = null;
    });
    list.append(btn);
  });

  return new Gtk.Popover({ child: list, autohide: true });
}

// helper that builds a widget for one application
function widgetForApp(app: Apps.Application): Gtk.Widget {
  const image = new Gtk.Image({
    icon_name: app.get_icon_name(),
    pixel_size: 32,
  });

  //-----------------------------------------------------------------------
  // NEW: use Gtk.MenuButton ⇢ it manages popover layout in GTK 4
  //-----------------------------------------------------------------------
  const menuButton = new Gtk.MenuButton({
    // ★
    has_frame: false, // no border
    can_shrink: true,
    direction: Gtk.ArrowType.UP, // pop over the bar
    css_classes: ['widget'],
  });
  menuButton.set_child(image); // show the icon

  // Left-click → launch
  const left = new Gtk.GestureClick({ button: 1 }); // ★
  left.connect('released', () => app.launch());
  menuButton.add_controller(left);

  // Right-click → build & show popover with actions
  const right = new Gtk.GestureClick({ button: 3 }); // ★
  right.connect('released', () => {
    // close any existing menu
    if (activePopover) {
      activePopover.popdown();
      activePopover = null;
    }

    const info = Gio.DesktopAppInfo.new(app.get_entry());
    if (!info) return;

    const acts = info.list_actions() ?? [];
    if (acts.length === 0) return;

    const pop = buildActionsPopover(info, acts); // build list
    menuButton.set_popover(pop); // attach to button :contentReference[oaicite:3]{index=3}
    pop.popup(); // show it          :contentReference[oaicite:4]{index=4}
    activePopover = pop;
  });
  menuButton.add_controller(right);

  // You can still wrap the button in your shared helper if you want
  // return createWidgetContainer(menuButton);    // optional
  return menuButton; // ★
}

// ----------------------------------------------------------------------------
// The rest of the file is untouched – only the widget factory changed
// ----------------------------------------------------------------------------

function queryApp(appName: string): Apps.Application {
  const apps = new Apps.Apps({
    nameMultiplier: 2,
    entryMultiplier: 0,
    executableMultiplier: 2,
  });
  for (const app of apps.fuzzy_query(appName)) return app;
  throw new Error(`App with name ${appName} not found`);
}

function exactApp(appName: string): Apps.Application {
  const apps = new Apps.Apps({
    nameMultiplier: 2,
    entryMultiplier: 0,
    executableMultiplier: 2,
  });
  for (const app of apps.exact_query(appName)) return app;
  throw new Error(`App with name ${appName} not found`);
}

export default function AppsWidget() {
  const appNames = [
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
      {appNames.map((name) => {
        try {
          const app = exactApp(name);
          return widgetForApp(app);
        } catch {
          return (
            <box orientation={Gtk.Orientation.HORIZONTAL} class="app-entry">
              <label
                label={`Error: Could not find app '${name}'.`}
                cssName="error"
              />
            </box>
          );
        }
      })}
    </box>
  );
}
