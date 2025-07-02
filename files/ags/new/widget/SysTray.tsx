import { For } from 'ags';
import { Gtk } from 'ags/gtk4';
import { Tray as AstalTray, TrayItem } from 'ags/gtk4/Astal';

export default function SysTray() {
  const tray = AstalTray.get_default();
  const items = tray.bind('items');

  return (
    <box orientation={Gtk.Orientation.HORIZONTAL} class="systray">
      <For each={items}>
        {(item: TrayItem) => (
          <button
            tooltipMarkup={item.bind('tooltip-markup')}
            onClicked={(_, ev) => item.activate(ev)}
            onSecondaryClicked={(_, ev) => item.secondary_activate(ev)}
          >
            <icon gicon={item.bind('gicon')} />
          </button>
        )}
      </For>
    </box>
  );
}
