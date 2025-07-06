import { Gtk } from 'ags/gtk4';

export type ClickHandler = (x: number, y: number) => void;

export function createWidgetContainer(
  child: Gtk.Widget,
  {
    css = ['widget'],
    onLeftClick,
    onRightClick,
  }: {
    css?: string[];
    onLeftClick?: ClickHandler;
    onRightClick?: ClickHandler;
  } = {}
): Gtk.Box {
  const box = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: css,
  });
  box.append(child);

  if (onLeftClick) {
    const left = new Gtk.GestureClick({ button: 1 });
    left.connect('released', (g) => {
      const ev = g.get_current_event();
      if (ev) {
        const [ok, x, y] = ev.get_position();
        if (ok) onLeftClick(x, y);
      }
    });
    box.add_controller(left);
  }

  if (onRightClick) {
    const right = new Gtk.GestureClick({ button: 3 });
    right.connect('released', (g) => {
      const ev = g.get_current_event();
      if (ev) {
        const [ok, x, y] = ev.get_position();
        if (ok) onRightClick(x, y);
      }
    });
    box.add_controller(right);
  }

  return box;
}
