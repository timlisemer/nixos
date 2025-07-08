import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import { createContainer } from '../../widget_helper/Container';
import {
  createCustomPopoverMenu,
  MenuAction,
} from '../../widget_helper/SharedPopoverMenu';

// ──────────────────────────────────────────────────────────
// centralised logging toggle – set DEBUG = true to re-enable
const DEBUG = false;
const log = (...args: unknown[]) => {
  if (DEBUG) console.log(...args);
};

// helper: detached spawn without DO_NOT_REAP_CHILD
const SPAWN_FLAGS = GLib.SpawnFlags.SEARCH_PATH;
const spawnAsyncDetached = (argv: string[]) =>
  GLib.spawn_async(null, argv, null, SPAWN_FLAGS, null);

function launchAppDetached(app: Apps.Application): void {
  try {
    const desktopFile = app.get_entry();
    if (!desktopFile) {
      log(`No desktop file for ${app.get_name()}`);
      return;
    }

    const success = spawnAsyncDetached(['gtk-launch', desktopFile]);
    if (success[0]) {
      log(`Launched detached: ${app.get_name()} (${desktopFile})`);
    } else {
      log(`Failed to launch detached: ${app.get_name()}`);
      app.launch();
    }
  } catch (error) {
    log(`Error launching ${app.get_name()}:`, error);
    try {
      app.launch();
    } catch (e) {
      log(`Final fallback failed for ${app.get_name()}:`, e);
    }
  }
}

function launchActionDetached(
  info: Gio.DesktopAppInfo,
  actionId: string
): void {
  try {
    const desktopId = info.get_id();
    if (!desktopId) {
      log(`No desktop ID for action ${actionId}`);
      return;
    }

    const success = spawnAsyncDetached(['gtk-launch', desktopId, actionId]);
    if (success[0]) {
      log(`Launched action detached: ${actionId}`);
    } else {
      log(`Failed to launch action detached: ${actionId}`);
      info.launch_action(actionId, null);
    }
  } catch (error) {
    log(`Error launching action ${actionId}:`, error);
    try {
      info.launch_action(actionId, null);
    } catch (e) {
      log(`Action launch fallback failed for ${actionId}:`, e);
    }
  }
}

function buildMenuActions(
  info: Gio.DesktopAppInfo,
  acts: string[],
  app: Apps.Application
): MenuAction[] {
  if (acts.length === 0) acts = ['__NEW_WINDOW__'];
  return acts.map((id) => ({
    id,
    label:
      id === '__NEW_WINDOW__' ? 'New Window' : (info.get_action_name(id) ?? id),
    callback: () =>
      id === '__NEW_WINDOW__'
        ? launchAppDetached(app)
        : launchActionDetached(info, id),
  }));
}

function widgetForApp(app: Apps.Application): Gtk.Widget {
  const image = new Gtk.Image({
    icon_name: app.get_icon_name(),
    pixel_size: 32,
  });
  const container = createContainer(image, {
    onLeftClick: () => launchAppDetached(app),
    onRightClick: () => {
      GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
        const info = Gio.DesktopAppInfo.new(app.get_entry());
        if (!info) return GLib.SOURCE_REMOVE;
        const menuActions = buildMenuActions(
          info,
          info.list_actions() ?? [],
          app
        );
        const appName = app.get_name() || app.get_entry() || 'Unknown App';
        createCustomPopoverMenu(container, menuActions, appName);
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
    <box orientation={Gtk.Orientation.HORIZONTAL} css_classes={['widget']}>
      {names.map((n) => {
        try {
          return widgetForApp(exactApp(n));
        } catch {
          return <label label={`${n} not found`} css_classes={['widget']} />;
        }
      })}
    </box>
  );
}
