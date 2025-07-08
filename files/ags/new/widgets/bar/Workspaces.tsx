import { createPoll } from 'ags/time';
import { Gtk } from 'ags/gtk4';
import { createContainer } from '../../widget_helper/Container';
import Hyprland from 'gi://AstalHyprland';

// ──────────────────────────────────────────────────────────
// helper: translate local-to-global workspace indices
export function getNthWorkspaceForMonitor(
  hyprland: any,
  monitorName: string,
  n: number
): { local_id: number; ws: Hyprland.Workspace } | null {
  // Collect unique workspaces for the monitor
  const wsArr = Array.from(
    new Map(
      hyprland
        .get_clients()
        .filter(
          (c: any) => c.get_workspace().get_monitor().name === monitorName
        )
        .map((c: any) => [Number(c.get_workspace().name), c.get_workspace()])
    ).entries()
  )
    .map(
      ([local_id, ws]) =>
        [local_id as number, ws as Hyprland.Workspace] as [
          number,
          Hyprland.Workspace,
        ]
    )
    .sort((a, b) => a[0] - b[0])
    .map(([local_id, ws]) => ({ local_id, ws }));

  /*print(
    `[getNthWorkspaceForMonitor] monitor=${monitorName}, n=${n}, ids=${JSON.stringify(
      wsArr.map((x) => x.local_id)
    )}, result=${wsArr[n] ? JSON.stringify(wsArr[n]) : null}`
  );*/

  return wsArr[n] ?? null;
}

// ──────────────────────────────────────────────────────────
export default function Workspaces(monitorName: string) {
  print(`[Workspaces] init for monitor='${monitorName}'`);

  const hyprland = Hyprland.get_default();

  // Main widget container with the "widget" css class
  const root = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: ['widget'],
    spacing: 8,
  });

  // helper: create a workspace indicator using a drawing area
  function createWorkspaceIndicator(
    workspaceId: number,
    isActive: boolean,
    isEmpty: boolean = false
  ): Gtk.Widget {
    const drawingArea = new Gtk.DrawingArea();
    drawingArea.set_size_request(24, 24);
    drawingArea.valign = Gtk.Align.CENTER;
    drawingArea.halign = Gtk.Align.CENTER;

    // Add appropriate CSS classes for styling
    if (isEmpty) {
      drawingArea.add_css_class('ws-indicator-empty');
    } else if (isActive) {
      drawingArea.add_css_class('ws-indicator-active');
    } else {
      drawingArea.add_css_class('ws-indicator-inactive');
    }

    // Custom drawing function for the workspace indicator
    drawingArea.set_draw_func((area, cr, width, height) => {
      const size = Math.min(width, height);
      const centerX = width / 2;
      const centerY = height / 2;
      const radius = size / 3;

      if (isEmpty) {
        // Draw a dashed circle for empty workspace
        cr.setLineCap(1); // CAIRO_LINE_CAP_ROUND
        cr.setLineWidth(2);
        cr.setSourceRGBA(0.6, 0.6, 0.6, 0.8);
        cr.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        cr.setDash([3, 3], 0);
        cr.stroke();
      } else if (isActive) {
        // Draw a filled circle for active workspace
        cr.setSourceRGBA(0.2, 0.7, 1.0, 1.0);
        cr.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        cr.fill();

        // Add a subtle border
        cr.setSourceRGBA(0.1, 0.5, 0.8, 1.0);
        cr.setLineWidth(1);
        cr.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        cr.stroke();
      } else {
        // Draw a filled circle for inactive workspace
        cr.setSourceRGBA(0.4, 0.4, 0.4, 0.8);
        cr.arc(centerX, centerY, radius - 2, 0, 2 * Math.PI);
        cr.fill();

        // Add a subtle border
        cr.setSourceRGBA(0.6, 0.6, 0.6, 0.8);
        cr.setLineWidth(1);
        cr.arc(centerX, centerY, radius - 2, 0, 2 * Math.PI);
        cr.stroke();
      }
    });

    // Wrap in createContainer for click handling
    const clickHandler = isEmpty
      ? () => {
          print(`Creating new workspace on monitor '${monitorName}'`);
          // TODO: Implement new workspace creation
        }
      : () => {
          print(
            `Switching to workspace ${workspaceId} on monitor '${monitorName}'`
          );
          // TODO: Implement workspace switching
        };

    return createContainer(drawingArea, {
      onLeftClick: clickHandler,
    });
  }

  function rebuildIndicator(): void {
    // print('── rebuildIndicator() ──');
    print(`── rebuildIndicator() ──  monitor='${monitorName}'`);

    // clear previous indicators
    let child = root.get_first_child();
    while (child) {
      root.remove(child);
      child = root.get_first_child();
    }

    // Get the monitor and its active workspace
    const monitor = hyprland.get_monitor_by_name(monitorName);
    const activeWorkspaceId = monitor
      ? Number(monitor.get_active_workspace().name)
      : null;

    // loop over getNthWorkspaceForMonitor() to get all workspaces on this monitor
    let workspaces: { local_id: number; ws: Hyprland.Workspace }[] = [];
    let activeWorkspace:
      | { local_id: number; ws: Hyprland.Workspace }
      | undefined;
    let idx = 0;
    while (true) {
      const result = getNthWorkspaceForMonitor(hyprland, monitorName, idx);
      if (!result) break;
      workspaces.push(result);

      // Check if this workspace is the active one for this monitor
      if (activeWorkspaceId !== null && result.local_id === activeWorkspaceId) {
        activeWorkspace = result;
      }
      idx++;
    }

    // If no workspaces found, create a default active one
    if (workspaces.length === 0 && activeWorkspaceId !== null) {
      workspaces.push({
        local_id: activeWorkspaceId,
        ws: monitor!.get_active_workspace(),
      });
      activeWorkspace = workspaces[0];
    }

    if (activeWorkspace === undefined && workspaces.length > 0) {
      activeWorkspace = workspaces[0];
    }

    let ids = workspaces.map((w) => w.local_id);

    // print(`  ids on monitor: ${JSON.stringify(ids)}`);
    // print(`  activeWorkspace on monitor: ${JSON.stringify(activeWorkspace?.local_id)}`);

    // build the workspace indicators
    ids.forEach((id) => {
      const isActive = id === activeWorkspace?.local_id;
      root.append(createWorkspaceIndicator(id, isActive));
    });

    // Always show an empty workspace indicator if there's only one workspace
    // or as a "create new" indicator
    if (workspaces.length <= 1) {
      root.append(createWorkspaceIndicator(-1, false, true));
    }

    // Count elements for debug
    let childCount = 0;
    let currentChild = root.get_first_child();
    while (currentChild) {
      childCount++;
      currentChild = currentChild.get_next_sibling();
    }
    // print(`  indicators in box: ${childCount} for monitor '${monitorName}'`);
    // print('── rebuildIndicator() END ── \n');
  }

  // ── connect to real Hyprland signals ────────────────────
  [
    // 'event', // generic IPC events (includes workspace switches)
    'client-added',
    'client-removed',
    'monitor-added',
    'monitor-removed',
    'workspace-added',
    'workspace-removed',
  ].forEach((sig) =>
    hyprland.connect(sig, (...args) => {
      print(`[Hyprland '${sig}'] → rebuildIndicator()`);
      rebuildIndicator();
    })
  );
  rebuildIndicator();

  return root;
}
