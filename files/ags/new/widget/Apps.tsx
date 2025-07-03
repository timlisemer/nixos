import Apps from 'gi://AstalApps';
import { Gtk } from 'ags/gtk4';

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
    css_classes: ['app-icon'],
  });

  const box = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: ['app-entry'],
  });
  box.append(image);

  const clickLeft = new Gtk.GestureClick({ button: 1 });
  clickLeft.connect('released', () =>
    console.log(`Left click on ${app.get_name()}`)
  );
  box.add_controller(clickLeft);

  const clickRight = new Gtk.GestureClick({ button: 3 });
  clickRight.connect('released', () =>
    console.log(`Right click on ${app.get_name()}`)
  );
  box.add_controller(clickRight);

  return box;
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
