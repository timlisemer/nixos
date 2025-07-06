import { Gtk } from 'ags/gtk4';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

// debug helper (shared with AppsWidget – duplicated here for isolation)
const DEBUG = false;
const log = (...args: unknown[]) => {
  if (DEBUG) console.log(...args);
};

// Map to track active popovers for each parent container
const activePopovers = new Map<Gtk.Widget, Gtk.Popover>();

export interface MenuAction {
  id: string;
  label: string;
  callback: () => void;
}

export function createCustomPopoverMenu(
  parent: Gtk.Widget,
  actions: MenuAction[],
  identifier: string
): void {
  const existingPopover = activePopovers.get(parent);
  if (existingPopover) {
    if (existingPopover.get_visible()) {
      existingPopover.popdown();
      activePopovers.delete(parent);
      log(`Closed existing popover for: ${identifier}`);
      return;
    }
    activePopovers.delete(parent);
  }

  const menuModel = new Gio.Menu();
  actions.forEach((action) =>
    menuModel.append(action.label, `app.${action.id}`)
  );

  const popover = new Gtk.PopoverMenu({ menu_model: menuModel });
  const actionGroup = new Gio.SimpleActionGroup();

  actions.forEach((action) => {
    const gAction = new Gio.SimpleAction({ name: action.id });
    gAction.connect('activate', () => {
      action.callback();
      const p = activePopovers.get(parent);
      if (p) {
        p.popdown();
        activePopovers.delete(parent);
      }
    });
    actionGroup.add_action(gAction);
  });

  popover.insert_action_group('app', actionGroup);
  activePopovers.set(parent, popover);
  popover.connect('closed', () => {
    activePopovers.delete(parent);
    log(`Popover closed for: ${identifier}`);
  });

  popover.set_parent(parent);
  popover.popup();
  log(`Custom popover menu opened for: ${identifier}`);
}

export function createSystemTrayPopoverMenu(
  parent: Gtk.Widget,
  item: any,
  identifier: string
): void {
  const existingPopover = activePopovers.get(parent);
  if (existingPopover) {
    if (existingPopover.get_visible()) {
      existingPopover.popdown();
      activePopovers.delete(parent);
      log(`Closed existing popover for: ${identifier}`);
      return;
    }
    activePopovers.delete(parent);
  }

  try {
    item.about_to_show();
    const menuModel = item.get_menu_model();
    if (menuModel) {
      const contextMenu = new Gtk.PopoverMenu({ menu_model: menuModel });
      activePopovers.set(parent, contextMenu);
      contextMenu.connect('closed', () => {
        activePopovers.delete(parent);
        log(`Popover closed for: ${identifier}`);
      });

      try {
        const ag = item.get_action_group();
        if (ag) {
          contextMenu.insert_action_group('dbusmenu', ag);
          log(`Action group 'dbusmenu' inserted for: ${identifier}`);
        }
      } catch (e) {
        log(`get_action_group failed for: ${identifier}`, e);
      }
      try {
        if (item.action_group) {
          contextMenu.insert_action_group('app', item.action_group);
          log(`Direct action group 'app' inserted for: ${identifier}`);
        }
      } catch (e) {
        log(`Direct action_group access failed for: ${identifier}`, e);
      }

      contextMenu.set_parent(parent);
      contextMenu.popup();
      log(`Menu model menu opened for: ${identifier}`);
      return;
    }
    log(`No menu model available for: ${identifier}`);
  } catch (error) {
    log(`Menu creation failed for: ${identifier}, error:`, error);
  }
}

export function cleanupAllPopovers(): void {
  activePopovers.forEach((popover) => {
    if (popover.get_visible()) popover.popdown();
  });
  activePopovers.clear();
}
