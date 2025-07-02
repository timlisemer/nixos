import { createPoll } from "ags/time";
import { Gtk } from "ags/gtk4";

export default function Time() {
  // Poll for the time string (HH:MM) every second
  const time = createPoll("", 1000, 'date "+%H:%M"');

  // Poll for the date string (DD.MM.YYYY) every second
  const date = createPoll("", 1000, 'date "+%d.%m.%Y"');

  return (
    <box 
          orientation={Gtk.Orientation.VERTICAL}
          class="widget"
    >
      <label label={time} cssName="clock-time" />
      <label label={date} cssName="clock-date" />
    </box>
  );
}