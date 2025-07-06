import { Gtk, Gdk } from 'ags/gtk4';

/**
 * AppMenu — container for launchers plus a search bar.
 * • centred horizontally, 150 px from the top of the Overview
 * • overall size: 40 % monitor width × 33 % monitor height
 */
export default function AppMenu(gdkmonitor: Gdk.Monitor): Gtk.Box {
  const { width, height } = gdkmonitor.get_geometry();

  /* outer menu container */
  const box = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    halign: Gtk.Align.CENTER,
    valign: Gtk.Align.START,
    hexpand: false,
    vexpand: false,
  });

  /* pixel size derived from monitor geometry */
  box.width_request = Math.round(width * 0.4);
  box.height_request = Math.round(height * 0.33);

  /* attach CSS class so style.scss rules apply */
  box.add_css_class('app-menu');

  /* ──────────────────────────────────────────────
     SEARCH BAR (50 px tall, full width, 10 px radius)
     ────────────────────────────────────────────── */
  const searchBar = new Gtk.Box({
    cssName: 'app-search-bar',
    hexpand: true, // fill horizontally
  });
  searchBar.height_request = 75; // fixed height
  searchBar.add_css_class('app-search-bar'); // ensure style

  /* search inside the bar */
  const innerSearchBar = new Gtk.Entry({
    placeholder_text: 'Search...',
    hexpand: true, // expand to full width of the bar
  });
  innerSearchBar.add_css_class('inner-search-bar'); // ensure style
  searchBar.append(innerSearchBar);

  // --- Focus handling ---
  // 1. Focus the entry when it appears
  innerSearchBar.connect('map', () => innerSearchBar.grab_focus());

  // 2. Focus the entry when the user clicks anywhere in the search bar
  const click = new Gtk.GestureClick();
  click.connect('pressed', () => innerSearchBar.grab_focus());
  searchBar.add_controller(click);

  box.append(searchBar);

  return box;
}
