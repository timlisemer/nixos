import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';
import { createWidgetContainer } from './WidgetContainer';
import Gio from 'gi://Gio'; // ★

function queryApp(appName: string): Apps.Application {
  const apps = new Apps.Apps({
    nameMultiplier: 2,
    entryMultiplier: 0,
    executableMultiplier: 2,
  });

  for (const app of apps.fuzzy_query(appName)) {
    const iconName = app.get_icon_name();
    const appName = app.get_name();
    console.log(`App Name: ${appName}, Icon Name: ${iconName}`);

    return app;
  }
  throw new Error(`App with name ${appName} not found`);
}

function exactApp(appName: string): Apps.Application {
  const apps = new Apps.Apps({
    nameMultiplier: 2,
    entryMultiplier: 0,
    executableMultiplier: 2,
  });

  for (const app of apps.exact_query(appName)) {
    const iconName = app.get_icon_name();
    const appName = app.get_name();
    console.log(`App Name: ${appName}, Icon Name: ${iconName}`);

    return app;
  }
  throw new Error(`App with name ${appName} not found`);
}

// helper that builds a widget for one application
function widgetForApp(app: Apps.Application): Gtk.Box {
  const image = new Gtk.Image({
    icon_name: app.get_icon_name(),
    pixel_size: 32,
  });

  // build via shared helper
  return createWidgetContainer(image, {
    onLeftClick: (x, y) => {
      console.log(`Left click on ${app.get_name()} at (${x},${y})`);
      app.launch();
    },
    onRightClick: (x, y) => {
      console.log(`Right click on ${app.get_name()} at (${x},${y})`);

      // ------------------------------------------------------------------ ★
      // OLD attempt – left here for reference
      // const infoOld = app.get_app() as Gio.DesktopAppInfo;

      // NEW – create DesktopAppInfo from desktop-file ID
      const info = Gio.DesktopAppInfo.new(app.get_entry());

      if (!info) {
        console.log(`No DesktopAppInfo for ${app.get_name()}`);
      } else {
        const acts = info.list_actions() ?? [];
        console.log(`Actions for ${app.get_name()}:`);
        acts.forEach((a) => console.log(` • ${a}`));
      }
      // ------------------------------------------------------------------ ★

      // existing debug dump
      console.log(
        `App Categories:\n${app.get_categories()} \n` +
          `App Entry: ${app.get_entry()} \n` +
          `App Executable: ${app.get_executable()} \n` +
          `App Frequency: ${app.get_frequency()} \n` +
          `App Icon Name: ${app.get_icon_name()} \n` +
          `App Keywords: ${app.get_keywords()}` +
          `App Name: ${app.get_name()} \n`
      );
    },
  });
}

export default function AppsWidget() {
  // The list of app names to display
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
    // A Horizontal box to hold the list of all app widgets
    <box orientation={Gtk.Orientation.HORIZONTAL} class="widget" spacing={8}>
      {/* Map each app name to a widget */}
      {appNames.map((name) => {
        try {
          // Attempt to find the exact application for the current name
          const app = exactApp(name);
          return widgetForApp(app); // If found, show its icon with click handlers
        } catch (error) {
          // If not found, display an error message for this specific app
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
