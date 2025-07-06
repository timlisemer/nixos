import { createPoll } from 'ags/time';
import { Gtk } from 'ags/gtk4';

export default function Time() {
  // Poll for the time string (HH:MM) every second
  const time = createPoll('', 1000, 'date "+%H:%M"');

  // Poll for the date string (DD.MM.YYYY) every second
  const date = createPoll('', 1000, 'date "+%d.%m.%Y"');

  // Build the clock widget (two stacked labels)
  const clockBox = (
    <box class="widget">
      <box
        orientation={Gtk.Orientation.VERTICAL}
        class="widget"
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <label label={time} cssName="clock-time" halign={Gtk.Align.CENTER} />
        <label label={date} cssName="clock-date" halign={Gtk.Align.CENTER} />
      </box>
    </box>
  ) as Gtk.Box;

  // Primary (left) click → log pointer coordinates
  const clickLeft = new Gtk.GestureClick({ button: 1 });
  clickLeft.connect('released', (gesture) => {
    const ev = gesture.get_current_event();
    if (ev) {
      const [ok, x, y] = ev.get_position();
      if (ok) console.log(`Clock left click at (${x},${y})`);
    }
  });
  clockBox.add_controller(clickLeft);

  // Secondary (right) click → log pointer coordinates
  const clickRight = new Gtk.GestureClick({ button: 3 });
  clickRight.connect('released', (gesture) => {
    const ev = gesture.get_current_event();
    if (ev) {
      const [ok, x, y] = ev.get_position();
      if (ok) console.log(`Clock right click at (${x},${y})`);
    }
  });
  clockBox.add_controller(clickRight);

  return clockBox;
}
