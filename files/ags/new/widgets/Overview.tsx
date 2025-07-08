import app from 'ags/gtk4/app';
import { Astal, Gdk, Gtk } from 'ags/gtk4';
import { createContainer } from '../widget_helper/Container';
import AppMenu from './overview/AppMenu';

/**
 * Overview window: dim background that closes on click,
 * plus an AppMenu that remains interactive.
 *
 * NOTE: gtk_overlay_set_overlay_pass_through() was removed in GTK 4.
 *       Overlay children simply receive events themselves; they do NOT
 *       propagate to the main child unless you set `can-target = false`.
 */
export default function Overview(gdkmonitor: Gdk.Monitor, index: number) {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  /* layer 1 — dim background that closes the overview */
  const dimLayer = createContainer(
    new Gtk.Box({ hexpand: true, vexpand: true }),
    {
      widget: false,
      overrideCss: ['overview'],
      onLeftClick: () => app.toggle_window(`overview-${index}`),
      onRightClick: () => app.toggle_window(`overview-${index}`),
    }
  );

  /* layer 2 — interactive AppMenu */
  const menuLayer = AppMenu(gdkmonitor);
  // menuLayer.can_target is TRUE by default, so it consumes pointer events.

  /* overlay combines both layers */
  const overlay = new Gtk.Overlay();
  overlay.set_child(dimLayer); // main child
  overlay.add_overlay(menuLayer); // overlay child

  return (
    <window
      name={`overview-${index}`}
      class="Overview"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      application={app}
      visible={false}
    >
      {overlay}
    </window>
  );
}
