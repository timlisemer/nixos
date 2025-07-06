import { Gtk } from 'ags/gtk4';

export type ClickHandler = (x: number, y: number) => void;

/** Options accepted by `createContainer` */
export interface ContainerOptions {
  css?: string[]; // existing param (kept)
  widget?: boolean; // NEW – defaults to true
  overrideCss?: string[]; // NEW – defaults to []
  onLeftClick?: ClickHandler;
  onRightClick?: ClickHandler;
}

export function createContainer(
  child: Gtk.Widget,
  {
    css = [''],
    widget = true,
    overrideCss = [],
    onLeftClick,
    onRightClick,
  }: ContainerOptions = {}
): Gtk.Box {
  if (widget) {
    child.add_css_class('widget');
  }

  const box = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    css_classes: overrideCss.length ? overrideCss : css,
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
