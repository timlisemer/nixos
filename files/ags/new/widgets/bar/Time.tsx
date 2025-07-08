import { createPoll } from 'ags/time';
import { Gtk } from 'ags/gtk4';
import { createContainer } from '../../widget_helper/Container'; // ★

export default function Time() {
  // Poll for the time string (HH:MM) every second
  const time = createPoll('', 1000, 'date "+%H:%M"');

  // Poll for the date string (DD.MM.YYYY) every second
  const date = createPoll('', 1000, 'date "+%d.%m.%Y"');

  const innerClock = (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      class="widget"
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    >
      <label label={time} cssName="clock-time" halign={Gtk.Align.CENTER} />
      <label label={date} cssName="clock-date" halign={Gtk.Align.CENTER} />
    </box>
  ) as Gtk.Box;

  // Build the clock widget using shared helper
  const clockBox = createContainer(innerClock, {
    onLeftClick: (x, y) => console.log(`Clock left click at (${x},${y})`),
    onRightClick: (x, y) => console.log(`Clock right click at (${x},${y})`),
  });

  return clockBox;
}
