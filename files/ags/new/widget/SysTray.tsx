import { For } from 'ags';
import { Systemtray } from 'ags/fetch/systemtray';
import { Gtk } from 'ags/gtk4';

export default function SysTray() {
  return (
    <box orientation={Gtk.Orientation.HORIZONTAL}>
      <For each={Systemtray.bind('items')}>
        {(item) => (
          <button
            onClicked={(_, event) => item.activate(event)}
            onSecondaryClicked={(_, event) => item.openMenu(event)}
            tooltipMarkup={item.bind('tooltip_markup')}
          >
            <icon icon={item.bind('icon')} />
          </button>
        )}
      </For>
    </box>
  );
}
