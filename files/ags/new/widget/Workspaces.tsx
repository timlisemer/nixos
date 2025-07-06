import { createPoll } from 'ags/time';
import { Gtk } from 'ags/gtk4';
import { createWidgetContainer } from './WidgetContainer';
import Hyprland from 'gi://AstalHyprland';

// ──────────────────────────────────────────────────────────
// helper: translate local-to-global workspace indices
export function getNthWorkspaceForMonitor(
  hyprland: any,
  monitorName: string,
  n: number
): number | null {
  const ids = Array.from(
    new Set<number>(
      hyprland
        .get_clients()
        .filter(
          (c: any) => c.get_workspace().get_monitor().name === monitorName
        )
        .map((c: any) => Number(c.get_workspace().name))
    )
  ).sort((a: number, b: number) => a - b);

  print(
    `[getNthWorkspaceForMonitor] monitor=${monitorName}, n=${n}, ids=${JSON.stringify(
      ids
    )}, result=${ids[n] ?? null}`
  );

  return ids[n] ?? null;
}

export default function Workspaces(monitorName: string) {
  print(`[Workspaces] init for monitor='${monitorName}'`);

  const hyprland = Hyprland.get_default();
  for (const client of hyprland.get_clients()) {
    print('\n\n\n\nclient.title ', client.title);
    print('client.get_monitor() ', client.get_monitor().name);
    print(
      'client.get_workspace().get_monitor().name ',
      client.get_workspace().get_monitor().name
    );
    print('client.get_workspace().name ', client.get_workspace().name);
  }

  const wsIndicator = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 6,
  });

  function rebuildIndicator(): void {
    print('── rebuildIndicator() ──');
    print(`  monitor='${monitorName}'`);

    // clear previous dots
    let child = wsIndicator.get_first_child();
    while (child) {
      wsIndicator.remove(child);
      child = wsIndicator.get_first_child();
    }

    // workspaces present on that monitor
    const ids = Array.from(
      new Set(
        hyprland
          .get_clients()
          .filter(
            (c: any) => c.get_workspace().get_monitor().name === monitorName
          )
          .map((c: any) => Number(c.get_workspace().name))
      )
    ).sort((a, b) => a - b);

    // active workspace = workspace of the focused client
    const focused = hyprland.get_clients().find((c: any) => c.focused === true);
    const activeId = focused
      ? Number(focused.get_workspace().name)
      : (ids.at(-1) ?? -1);

    print(`  ids on monitor: ${JSON.stringify(ids)}`);
    print(`  activeId: ${activeId}`);

    // build the dots for the workspaces on this monitor
    ids.forEach((id) => {
      const lbl = new Gtk.Label({ label: ' ' }); // ← blank, CSS paints circle
      lbl.add_css_class(id === activeId ? 'ws-dot-active' : 'ws-dot');
      wsIndicator.append(lbl);
    });

    // visual hint that another workspace can be spawned
    const emptyLbl = new Gtk.Label({ label: ' ' }); // ← blank
    emptyLbl.add_css_class('ws-dot-empty');
    wsIndicator.append(emptyLbl);

    // Count elements in the box by looping through children starting from the first child
    let childCount = 0;
    let currentChild = wsIndicator.get_first_child();
    while (currentChild) {
      childCount++;
      currentChild = currentChild.get_next_sibling();
    }
    print(`  dots in box: ${childCount} for monitor '${monitorName}'`);
    print('── rebuildIndicator() END ── \n');
  }

  // keep indicator in sync (with extra logging on each signal)
  [
    'event', // generic Hyprland IPC events
    'client-added',
    'client-removed',
    'workspace-added',
    'workspace-removed',
  ].forEach((sig) =>
    hyprland.connect(sig, (...args) => {
      print(`[Hyprland signal '${sig}'] → rebuildIndicator()`);
      rebuildIndicator();
    })
  );
  rebuildIndicator();

  // ─── wrap in shared helper ──────────────────────────────
  const worspacesBox = createWidgetContainer(wsIndicator, {
    onLeftClick: (x, y) => console.log(`worspaces left click at (${x},${y})`),
    onRightClick: (x, y) => console.log(`worspaces right click at (${x},${y})`),
  });

  return worspacesBox;
}
